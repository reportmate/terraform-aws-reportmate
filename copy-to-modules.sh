#!/bin/bash

# ReportMate Modularization Script
# Copies current monorepo to new modular structure

set -e

BASE_DIR="/Users/rod/Developer/reportmate"
SOURCE_DIR="/Users/rod/DevOps/ReportMate"

echo "Starting ReportMate modularization..."
echo "Source: $SOURCE_DIR"
echo "Target: $BASE_DIR"

# Create base directory structure
echo "Creating directory structure..."
mkdir -p "$BASE_DIR"/{reportmate-app-csharp,reportmate-app-swift,reportmate-app-web,reportmate-infra-aws,reportmate-infra-azure,reportmate-module-core,reportmate-module-hardware,reportmate-module-software}

# Copy React/Next.js app (apps/www -> reportmate-app-web)
echo "Copying React app..."
if [ -d "$SOURCE_DIR/apps/www" ]; then
    cp -r "$SOURCE_DIR/apps/www/"* "$BASE_DIR/reportmate-app-web/"
    echo "React app copied to reportmate-app-web"
else
    echo "No www app found"
fi

# Copy C# app (apps/csharp -> reportmate-app-csharp)
echo "Copying C# app..."
if [ -d "$SOURCE_DIR/apps/csharp" ] && [ "$(ls -A $SOURCE_DIR/apps/csharp)" ]; then
    cp -r "$SOURCE_DIR/apps/csharp/"* "$BASE_DIR/reportmate-app-csharp/"
    echo "C# app copied to reportmate-app-csharp"
else
    echo "No C# app content found"
fi

# Copy Swift app (apps/swift -> reportmate-app-swift)
echo "Copying Swift app..."
if [ -d "$SOURCE_DIR/apps/swift" ] && [ "$(ls -A $SOURCE_DIR/apps/swift)" ]; then
    cp -r "$SOURCE_DIR/apps/swift/"* "$BASE_DIR/reportmate-app-swift/"
    echo "Swift app copied to reportmate-app-swift"
else
    echo "ℹ️  No Swift app content found"
fi

# Copy Azure infrastructure components to reportmate-infra-azure
echo "☁️  Copying Azure infrastructure..."
cp -r "$SOURCE_DIR/infrastructure/"* "$BASE_DIR/reportmate-infra-azure/"
cp -r "$SOURCE_DIR/functions" "$BASE_DIR/reportmate-infra-azure/"
cp -r "$SOURCE_DIR/database" "$BASE_DIR/reportmate-infra-azure/"
cp -r "$SOURCE_DIR/pipelines" "$BASE_DIR/reportmate-infra-azure/"
cp -r "$SOURCE_DIR/scripts" "$BASE_DIR/reportmate-infra-azure/"
cp -r "$SOURCE_DIR/docs" "$BASE_DIR/reportmate-infra-azure/"

# Copy configuration files
cp "$SOURCE_DIR/azure.yaml" "$BASE_DIR/reportmate-infra-azure/"
cp "$SOURCE_DIR/deploy.sh" "$BASE_DIR/reportmate-infra-azure/"
cp "$SOURCE_DIR/docker-compose.yml" "$BASE_DIR/reportmate-infra-azure/"
cp "$SOURCE_DIR/README.md" "$BASE_DIR/reportmate-infra-azure/"
cp "$SOURCE_DIR/package.json" "$BASE_DIR/reportmate-infra-azure/"
[ -f "$SOURCE_DIR/pnpm-lock.yaml" ] && cp "$SOURCE_DIR/pnpm-lock.yaml" "$BASE_DIR/reportmate-infra-azure/"
[ -f "$SOURCE_DIR/pnpm-workspace.yaml" ] && cp "$SOURCE_DIR/pnpm-workspace.yaml" "$BASE_DIR/reportmate-infra-azure/"

echo "Azure infrastructure copied to reportmate-infra-azure"

# Copy Windows client to module-software
echo "🖥️  Copying Windows client to module-software..."
if [ -d "$SOURCE_DIR/clients/windows" ]; then
    cp -r "$SOURCE_DIR/clients" "$BASE_DIR/reportmate-module-software/"
    echo "Windows client copied to reportmate-module-software"
else
    echo "No Windows client found"
fi

# Create placeholder AWS infrastructure
echo "🌩️  Creating AWS infrastructure placeholder..."
cat > "$BASE_DIR/reportmate-infra-aws/README.md" << 'EOF'
# ReportMate AWS Infrastructure

This repository will contain AWS-specific infrastructure code (Terraform/CDK) for deploying ReportMate on AWS.

## Coming Soon
- Terraform modules for AWS deployment
- CloudFormation templates
- AWS Lambda functions
- RDS/DynamoDB configurations
EOF

# Create placeholder core module
echo "Creating core module placeholder..."
cat > "$BASE_DIR/reportmate-module-core/README.md" << 'EOF'
# ReportMate Core Module

This repository contains the core business logic and shared components for ReportMate.

## Coming Soon
- Shared data models
- Business logic components
- Common utilities
- API contracts
EOF

# Create placeholder hardware module
echo "🔌 Creating hardware module placeholder..."
cat > "$BASE_DIR/reportmate-module-hardware/README.md" << 'EOF'
# ReportMate Hardware Module

This repository contains hardware-specific adapters and integrations for ReportMate.

## Coming Soon
- Hardware detection logic
- Platform-specific adapters
- Device information collectors
- Hardware monitoring components
EOF

# Summary
echo ""
echo "Modularization complete!"
echo ""
echo "Summary:"
echo "   reportmate-app-web: Next.js web dashboard"
echo "   🔷 reportmate-app-csharp: C# client libraries"
echo "   🍎 reportmate-app-swift: Swift/iOS client libraries"
echo "   ☁️  reportmate-infra-azure: Complete Azure infrastructure"
echo "   🌩️  reportmate-infra-aws: AWS infrastructure (placeholder)"
echo "   reportmate-module-core: Core business logic (placeholder)"
echo "   🔌 reportmate-module-hardware: Hardware adapters (placeholder)"
echo "   🖥️  reportmate-module-software: OS/software telemetry"
echo ""
echo "Next steps:"
echo "1. Initialize git repositories in each directory"
echo "2. Set up GitHub repositories"
echo "3. Configure CI/CD pipelines for each module"
echo "4. Update cross-module dependencies"
