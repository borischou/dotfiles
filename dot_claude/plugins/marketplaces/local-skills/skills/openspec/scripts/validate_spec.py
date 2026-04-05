#!/usr/bin/env python3
"""
Lightweight OpenSpec validation script for quick checks.
For comprehensive validation, use: openspec validate <change-id> --strict
"""

import re
import sys
from pathlib import Path


def validate_spec_file(file_path: Path) -> list[str]:
    """Validate a single spec file and return list of errors."""
    errors = []
    content = file_path.read_text()

    # Check for delta operations
    has_delta = any(
        op in content
        for op in ["## ADDED Requirements", "## MODIFIED Requirements",
                   "## REMOVED Requirements", "## RENAMED Requirements"]
    )

    if not has_delta:
        errors.append(f"{file_path}: No delta operations found (ADDED/MODIFIED/REMOVED/RENAMED)")
        return errors

    # Find all requirements
    requirement_pattern = r'^###\s+Requirement:\s+(.+)$'
    requirements = re.findall(requirement_pattern, content, re.MULTILINE)

    if not requirements:
        errors.append(f"{file_path}: No requirements found")
        return errors

    # Check each requirement has at least one scenario
    for req_name in requirements:
        # Find the section for this requirement
        req_section_pattern = rf'###\s+Requirement:\s+{re.escape(req_name)}.*?(?=###|\Z)'
        req_section = re.search(req_section_pattern, content, re.DOTALL)

        if req_section:
            section_text = req_section.group(0)
            # Check for scenario with exactly 4 hashtags
            if not re.search(r'^####\s+Scenario:', section_text, re.MULTILINE):
                errors.append(
                    f"{file_path}: Requirement '{req_name}' has no scenarios. "
                    "Use '#### Scenario: <name>' format"
                )

    # Check for normative language in requirements
    for req_name in requirements:
        req_pattern = rf'###\s+Requirement:\s+{re.escape(req_name)}(.*?)(?=###|\Z)'
        req_match = re.search(req_pattern, content, re.DOTALL)

        if req_match:
            req_text = req_match.group(1)
            # Extract the first paragraph after requirement header
            first_para = req_text.split('\n\n')[0].strip()
            if first_para and '####' not in first_para:
                if not any(word in first_para.upper() for word in ['SHALL', 'MUST', 'SHOULD']):
                    errors.append(
                        f"{file_path}: Requirement '{req_name}' should use normative language "
                        "(SHALL/MUST/SHOULD)"
                    )

    return errors


def validate_change(change_path: Path) -> list[str]:
    """Validate a complete change directory."""
    errors = []

    # Check required files
    required_files = {
        'proposal.md': 'Change proposal describing why and what',
        'tasks.md': 'Implementation task checklist'
    }

    for filename, description in required_files.items():
        file_path = change_path / filename
        if not file_path.exists():
            errors.append(f"{change_path.name}: Missing {filename} ({description})")

    # Check for spec deltas
    specs_dir = change_path / 'specs'
    if not specs_dir.exists():
        errors.append(f"{change_path.name}: Missing specs/ directory with delta files")
        return errors

    spec_files = list(specs_dir.rglob('*.md'))
    if not spec_files:
        errors.append(f"{change_path.name}: No spec files found in specs/ directory")
        return errors

    # Validate each spec file
    for spec_file in spec_files:
        errors.extend(validate_spec_file(spec_file))

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_spec.py <path-to-change-or-spec-file>")
        print("\nExamples:")
        print("  python validate_spec.py openspec/changes/add-feature/")
        print("  python validate_spec.py openspec/changes/add-feature/specs/auth/spec.md")
        sys.exit(1)

    path = Path(sys.argv[1])

    if not path.exists():
        print(f"Error: Path not found: {path}")
        sys.exit(1)

    errors = []

    if path.is_file() and path.suffix == '.md':
        # Validate single spec file
        errors = validate_spec_file(path)
    elif path.is_dir():
        # Validate change directory
        errors = validate_change(path)
    else:
        print(f"Error: Expected a .md file or directory, got: {path}")
        sys.exit(1)

    if errors:
        print("❌ Validation failed:\n")
        for error in errors:
            print(f"  • {error}")
        print("\n💡 For comprehensive validation, run: openspec validate <change-id> --strict")
        sys.exit(1)
    else:
        print("✅ Validation passed!")
        print("💡 Consider running full validation: openspec validate <change-id> --strict")
        sys.exit(0)


if __name__ == '__main__':
    main()
