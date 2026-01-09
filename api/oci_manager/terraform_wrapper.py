"""Terraform wrapper for managing OCI infrastructure."""

import json
import logging
import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class TerraformOutput:
    """Terraform apply output."""
    success: bool
    outputs: dict
    error: Optional[str] = None


class TerraformWrapper:
    """Wrapper for Terraform CLI operations."""

    def __init__(self, working_dir: Path, var_file: Optional[Path] = None):
        """
        Initialize Terraform wrapper.

        Args:
            working_dir: Directory containing Terraform files
            var_file: Path to terraform.tfvars file
        """
        self.working_dir = Path(working_dir)
        self.var_file = Path(var_file) if var_file else self.working_dir / "terraform.tfvars"
        self._check_terraform()

    def _check_terraform(self):
        """Verify Terraform is installed."""
        try:
            result = subprocess.run(
                ["terraform", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode != 0:
                raise RuntimeError("Terraform not found")
            logger.debug(f"Terraform version: {result.stdout.splitlines()[0]}")
        except FileNotFoundError:
            raise RuntimeError("Terraform is not installed. Install from https://terraform.io")

    def _run_terraform(self, args: list, timeout: int = 600) -> subprocess.CompletedProcess:
        """Run a Terraform command."""
        cmd = ["terraform"] + args
        logger.debug(f"Running: {' '.join(cmd)}")

        env = os.environ.copy()
        env["TF_IN_AUTOMATION"] = "1"  # Cleaner output

        return subprocess.run(
            cmd,
            cwd=self.working_dir,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env
        )

    def init(self) -> bool:
        """Initialize Terraform working directory."""
        logger.info("Initializing Terraform...")
        result = self._run_terraform(["init", "-input=false"])
        if result.returncode != 0:
            logger.error(f"Terraform init failed: {result.stderr}")
            return False
        return True

    def validate(self) -> bool:
        """Validate Terraform configuration."""
        result = self._run_terraform(["validate", "-json"])
        if result.returncode != 0:
            logger.error(f"Terraform validate failed: {result.stderr}")
            return False
        return True

    def plan(self, session_id: str, extra_vars: Optional[dict] = None) -> bool:
        """
        Create Terraform execution plan.

        Args:
            session_id: Unique session identifier
            extra_vars: Additional variables to pass

        Returns:
            True if plan succeeds
        """
        args = ["plan", "-input=false", "-out=tfplan"]

        if self.var_file.exists():
            args.extend(["-var-file", str(self.var_file)])

        args.extend(["-var", f"session_id={session_id}"])

        if extra_vars:
            for key, value in extra_vars.items():
                args.extend(["-var", f"{key}={value}"])

        result = self._run_terraform(args, timeout=120)
        if result.returncode != 0:
            logger.error(f"Terraform plan failed: {result.stderr}")
            return False
        return True

    def apply(self, session_id: str, extra_vars: Optional[dict] = None) -> TerraformOutput:
        """
        Apply Terraform configuration to create resources.

        Args:
            session_id: Unique session identifier
            extra_vars: Additional variables to pass

        Returns:
            TerraformOutput with results
        """
        logger.info(f"Creating OCI resources for session {session_id}...")

        args = ["apply", "-input=false", "-auto-approve", "-json"]

        if self.var_file.exists():
            args.extend(["-var-file", str(self.var_file)])

        args.extend(["-var", f"session_id={session_id}"])

        if extra_vars:
            for key, value in extra_vars.items():
                args.extend(["-var", f"{key}={value}"])

        result = self._run_terraform(args, timeout=600)  # 10 min timeout

        if result.returncode != 0:
            # Parse error from JSON output
            error_msg = self._parse_terraform_error(result.stdout, result.stderr)
            logger.error(f"Terraform apply failed: {error_msg}")
            return TerraformOutput(success=False, outputs={}, error=error_msg)

        # Get outputs
        outputs = self.get_outputs()
        return TerraformOutput(success=True, outputs=outputs)

    def destroy(self, session_id: str) -> bool:
        """
        Destroy Terraform-managed resources.

        Args:
            session_id: Session identifier (for logging)

        Returns:
            True if destroy succeeds
        """
        logger.info(f"Destroying OCI resources for session {session_id}...")

        args = ["destroy", "-input=false", "-auto-approve"]

        if self.var_file.exists():
            args.extend(["-var-file", str(self.var_file)])

        args.extend(["-var", f"session_id={session_id}"])

        result = self._run_terraform(args, timeout=600)

        if result.returncode != 0:
            logger.error(f"Terraform destroy failed: {result.stderr}")
            return False

        logger.info(f"Successfully destroyed resources for session {session_id}")
        return True

    def get_outputs(self) -> dict:
        """Get Terraform outputs as dictionary."""
        result = self._run_terraform(["output", "-json"])
        if result.returncode != 0:
            logger.warning(f"Failed to get outputs: {result.stderr}")
            return {}

        try:
            raw_outputs = json.loads(result.stdout)
            # Extract values from Terraform output format
            return {k: v.get("value") for k, v in raw_outputs.items()}
        except json.JSONDecodeError:
            logger.warning("Failed to parse Terraform outputs")
            return {}

    def get_state(self) -> Optional[dict]:
        """Get current Terraform state."""
        result = self._run_terraform(["show", "-json"])
        if result.returncode != 0:
            return None
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return None

    def _parse_terraform_error(self, stdout: str, stderr: str) -> str:
        """Parse error message from Terraform JSON output."""
        # Try to parse JSON lines from stdout
        for line in stdout.splitlines():
            try:
                msg = json.loads(line)
                if msg.get("@level") == "error":
                    return msg.get("diagnostic", {}).get("summary", str(msg))
            except json.JSONDecodeError:
                continue

        # Fall back to stderr
        return stderr or "Unknown error"


class WorkspaceManager:
    """
    Manages isolated Terraform workspaces for concurrent sessions.

    Each session gets its own state file to allow multiple concurrent sessions.
    """

    def __init__(self, base_dir: Path, template_dir: Path):
        """
        Initialize workspace manager.

        Args:
            base_dir: Base directory for session workspaces
            template_dir: Directory containing Terraform template files
        """
        self.base_dir = Path(base_dir)
        self.template_dir = Path(template_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    def create_workspace(self, session_id: str) -> Path:
        """
        Create an isolated workspace for a session.

        Args:
            session_id: Unique session identifier

        Returns:
            Path to the workspace directory
        """
        workspace_dir = self.base_dir / session_id
        workspace_dir.mkdir(parents=True, exist_ok=True)

        # Symlink Terraform files from template
        for tf_file in self.template_dir.glob("*.tf"):
            link_path = workspace_dir / tf_file.name
            if not link_path.exists():
                link_path.symlink_to(tf_file.resolve())

        # Copy tfvars if exists
        tfvars = self.template_dir / "terraform.tfvars"
        if tfvars.exists():
            import shutil
            shutil.copy(tfvars, workspace_dir / "terraform.tfvars")

        return workspace_dir

    def delete_workspace(self, session_id: str):
        """Delete a session workspace."""
        workspace_dir = self.base_dir / session_id
        if workspace_dir.exists():
            import shutil
            shutil.rmtree(workspace_dir)

    def get_workspace(self, session_id: str) -> Optional[Path]:
        """Get path to existing workspace."""
        workspace_dir = self.base_dir / session_id
        if workspace_dir.exists():
            return workspace_dir
        return None

    def list_workspaces(self) -> list:
        """List all session workspaces."""
        return [d.name for d in self.base_dir.iterdir() if d.is_dir()]
