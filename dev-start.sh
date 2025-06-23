#!/bin/bash
# Local development with Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Reportmate Local Development Setup${NC}"

# Check if .env file exists, if not copy from example
if [ ! -f .env ]; then
    echo -e "${YELLOW}📋 Creating .env file from example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please update .env with your actual Azure credentials${NC}"
fi

# Start services
echo -e "${YELLOW}🐳 Starting Docker Compose services...${NC}"
docker-compose up --build -d

echo -e "${GREEN}✅ Services started successfully!${NC}"
echo -e "${GREEN}🌐 Frontend: http://localhost:3000${NC}"
echo -e "${GREEN}🗄️  PostgreSQL: localhost:5432${NC}"
echo -e "${GREEN}📦 Redis: localhost:6379${NC}"

echo -e "${YELLOW}📋 To view logs:${NC}"
echo "  docker-compose logs -f"

echo -e "${YELLOW}🛑 To stop services:${NC}"
echo "  docker-compose down"

echo -e "${YELLOW}🔄 To restart services:${NC}"
echo "  docker-compose restart"
