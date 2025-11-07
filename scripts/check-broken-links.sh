#!/bin/bash

# 깨진 링크 자동 검증 스크립트
# 사용법: ./scripts/check-broken-links.sh

set -e

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프로젝트 루트 디렉토리
PROJECT_ROOT="/Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management"
DOCS_DIR="$PROJECT_ROOT/docs"
REPORT_FILE="$DOCS_DIR/context-tracking/broken-links-report.md"
CSV_FILE="$DOCS_DIR/context-tracking/broken-links.csv"

# 카운터
TOTAL_LINKS=0
BROKEN_LINKS=0
VALID_LINKS=0

echo -e "${YELLOW}=== 깨진 링크 검증 시작 ===${NC}"
echo "검사 대상: $DOCS_DIR"
echo ""

# CSV 헤더 생성
echo "소스파일,링크텍스트,링크경로,상태,대체파일제안" > "$CSV_FILE"

# 임시 파일
TEMP_LINKS="/tmp/all_links.txt"
> "$TEMP_LINKS"

# 모든 .md 파일에서 링크 추출
echo -e "${YELLOW}1. 링크 추출 중...${NC}"
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    # 상대 경로로 변환
    rel_file="${file#$PROJECT_ROOT/}"

    # [text](path.md) 형식의 링크 추출
    # macOS의 grep은 -P 옵션을 지원하지 않으므로 -E 사용
    grep -Eo '\[[^]]+\]\([^)]+\.md[^)]*\)' "$file" 2>/dev/null | while read -r link; do
        # 링크 텍스트와 경로 분리
        link_text=$(echo "$link" | sed -E 's/\[([^]]+)\].*/\1/')
        link_path=$(echo "$link" | sed -E 's/.*\(([^)]+)\).*/\1/')

        # 앵커 제거 (예: file.md#section → file.md)
        link_path_no_anchor="${link_path%%#*}"

        echo "$rel_file|$link_text|$link_path_no_anchor" >> "$TEMP_LINKS"
    done
done

# 링크 검증
echo -e "${YELLOW}2. 링크 검증 중...${NC}"
while IFS='|' read -r source_file link_text link_path; do
    TOTAL_LINKS=$((TOTAL_LINKS + 1))

    # 소스 파일의 디렉토리
    source_dir=$(dirname "$PROJECT_ROOT/$source_file")

    # 절대 경로로 변환
    if [[ "$link_path" == /* ]]; then
        # 절대 경로인 경우
        abs_path="$PROJECT_ROOT$link_path"
    elif [[ "$link_path" == http* ]]; then
        # 외부 링크는 건너뜀
        VALID_LINKS=$((VALID_LINKS + 1))
        continue
    else
        # 상대 경로인 경우
        abs_path="$(cd "$source_dir" && realpath "$link_path" 2>/dev/null || echo "")"
    fi

    # 파일 존재 여부 확인
    if [ -z "$abs_path" ] || [ ! -f "$abs_path" ]; then
        BROKEN_LINKS=$((BROKEN_LINKS + 1))

        # 대체 파일 제안 (파일명 기반 검색)
        filename=$(basename "$link_path")
        suggestions=$(find "$DOCS_DIR" -name "$filename" -type f 2>/dev/null | head -3 | xargs -I {} bash -c 'echo "{}" | sed "s|'$PROJECT_ROOT'/||g"' | tr '\n' '; ')

        if [ -z "$suggestions" ]; then
            suggestions="파일 없음"
        fi

        # CSV 저장
        echo "\"$source_file\",\"$link_text\",\"$link_path\",\"BROKEN\",\"$suggestions\"" >> "$CSV_FILE"

        echo -e "${RED}[BROKEN]${NC} $source_file -> $link_path"
    else
        VALID_LINKS=$((VALID_LINKS + 1))
        echo "\"$source_file\",\"$link_text\",\"$link_path\",\"VALID\",\"\"" >> "$CSV_FILE"
    fi
done < "$TEMP_LINKS"

# 통계 출력
echo ""
echo -e "${YELLOW}=== 검증 완료 ===${NC}"
echo -e "총 링크 수: ${YELLOW}$TOTAL_LINKS${NC}"
echo -e "정상 링크: ${GREEN}$VALID_LINKS${NC}"
echo -e "깨진 링크: ${RED}$BROKEN_LINKS${NC}"

if [ $BROKEN_LINKS -eq 0 ]; then
    echo -e "${GREEN}✅ 모든 링크가 정상입니다!${NC}"
else
    echo -e "${RED}⚠️  깨진 링크를 수정해야 합니다.${NC}"
fi

echo ""
echo "상세 리포트: $REPORT_FILE"
echo "CSV 파일: $CSV_FILE"

# 마크다운 리포트 생성
echo -e "${YELLOW}3. 리포트 생성 중...${NC}"

# 퍼센티지 계산 (0으로 나누기 방지)
if [ $TOTAL_LINKS -eq 0 ]; then
    VALID_PERCENT="0.0"
    BROKEN_PERCENT="0.0"
else
    VALID_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($VALID_LINKS/$TOTAL_LINKS)*100}")
    BROKEN_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($BROKEN_LINKS/$TOTAL_LINKS)*100}")
fi

cat > "$REPORT_FILE" <<EOF
# 깨진 링크 검증 리포트

**생성일**: $(date '+%Y-%m-%d %H:%M:%S')
**검사 대상**: $DOCS_DIR

## 📊 요약

- **총 링크 수**: $TOTAL_LINKS
- **정상 링크**: $VALID_LINKS (${VALID_PERCENT}%)
- **깨진 링크**: $BROKEN_LINKS (${BROKEN_PERCENT}%)

---

## 🔴 깨진 링크 목록

EOF

# 깨진 링크만 필터링하여 리포트에 추가
awk -F',' 'NR>1 && $4=="\"BROKEN\"" {print}' "$CSV_FILE" | while IFS=',' read -r source link_text link_path status suggestions; do
    # 따옴표 제거
    source=$(echo "$source" | tr -d '"')
    link_text=$(echo "$link_text" | tr -d '"')
    link_path=$(echo "$link_path" | tr -d '"')
    suggestions=$(echo "$suggestions" | tr -d '"')

    cat >> "$REPORT_FILE" <<EOF
### \`$source\`

- **링크 텍스트**: $link_text
- **링크 경로**: \`$link_path\`
- **대체 파일 제안**: $suggestions

EOF
done

if [ $BROKEN_LINKS -eq 0 ]; then
    echo "✅ 깨진 링크가 없습니다!" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<EOF

---

## 🔗 관련 문서
- [Link Mapping Table](link-mapping-table.md)
- [Documentation Improvement Action Plan](documentation-improvement-action-plan.md)
- [Sync Status](sync-status.md)

---

## 🔧 자동 수정 방법

1. **링크 매핑 테이블 확인**:
   \`\`\`bash
   cat docs/context-tracking/link-mapping-table.md
   \`\`\`

2. **자동 링크 업데이트** (작성 예정):
   \`\`\`bash
   ./scripts/update-links.sh
   \`\`\`

3. **수동 수정** (대체 파일이 없는 경우):
   - 삭제된 파일의 내용이 어디로 이동했는지 확인
   - 관련 개념 문서나 구현 가이드에서 해당 내용 검색
   - 적절한 새 링크로 교체
EOF

echo -e "${GREEN}✅ 리포트 생성 완료!${NC}"
echo ""

# 종료 코드
if [ $BROKEN_LINKS -gt 0 ]; then
    exit 1
else
    exit 0
fi
