#!/bin/bash
# Git Hooks 설치 스크립트
# Worktree 생성 시 .env 등의 파일을 자동으로 복사하는 Hook을 활성화합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "🔧 Git Hooks 설치"
echo "================================================"
echo ""

# Git 저장소 확인
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Git 저장소가 아닙니다: $PROJECT_ROOT"
    exit 1
fi

# .githooks 디렉토리 확인
if [ ! -d "$PROJECT_ROOT/.githooks" ]; then
    echo "❌ .githooks 디렉토리가 없습니다"
    exit 1
fi

# Git 설정 변경
echo "📝 Git hooks 경로 설정 중..."
cd "$PROJECT_ROOT"
git config core.hooksPath .githooks
chmod +x "$PROJECT_ROOT"/.githooks/*

echo "✅ Git hooks 경로 설정 완료: .githooks"
echo ""

# 설정 확인
HOOKS_PATH=$(git config --get core.hooksPath)
if [ "$HOOKS_PATH" = ".githooks" ]; then
    echo "✅ 설치 완료!"
    echo ""
    echo "📦 활성화된 Hooks:"
    ls -1 .githooks/ | while read hook; do
        echo "   - $hook"
    done
    echo ""
    echo "🚀 이제 git worktree를 사용할 때 .env 파일이 자동으로 복사됩니다!"
else
    echo "⚠️  설정 확인 필요: $HOOKS_PATH"
fi

echo "================================================"
