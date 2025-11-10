# Baseline Metrics for SC-005 Validation

**Feature**: Workspace Navigation Refactoring (001-workspace-navigation-refactor)
**Measured Date**: [TBD - To be measured in T008.5]
**Target**: 40% maintainability improvement

## Success Criteria

**SC-005**: Code maintainability improves by at least 40%:
- Cyclomatic complexity < 10 per function (measured by flutter_analyze)
- Coupling < 5 module dependencies per file
- Cohesion > 0.7 using Lack of Cohesion of Methods (LCOM) metric
- **Baseline**: current workspace_page.dart complexity ~15, coupling ~8

---

## Current State (Before Refactoring)

**Status**: ✅ Measured on 2025-11-09 (Task T008.5 completed)

### workspace_page.dart

**File Path**: `frontend/lib/presentation/pages/workspace/workspace_page.dart`

- **Lines of Code**: 251 lines
  - Target: <150 lines (40% reduction)
- **Module Coupling**: 17 import statements
  - Target: <10 imports (41% reduction - exceeds 40% goal!)
- **Method Count**: 18 methods
  - Target: <11 methods (39% reduction)
- **Class Count**: 2 classes
  - Target: Extract to separate files if >1 class remains
- **Cyclomatic Complexity**: Not measured (requires detailed analysis)
  - Estimated: ~15 per spec baseline
  - Target: <10 per function (33% reduction)
- **LCOM Metric**: Not measured (requires IDE plugin)
  - Target: >0.7 cohesion

### Measurement Commands

```bash
# Cyclomatic complexity and linting issues
flutter analyze frontend/lib/presentation/pages/workspace/workspace_page.dart

# Lines of code
wc -l frontend/lib/presentation/pages/workspace/workspace_page.dart

# Count import statements (coupling)
grep -c "^import " frontend/lib/presentation/pages/workspace/workspace_page.dart

# Count methods
grep -c "^\s*\(void\|Future\|Widget\)" frontend/lib/presentation/pages/workspace/workspace_page.dart
```

---

## Target State (After Refactoring)

### Complexity Goals

- **Cyclomatic Complexity**: <10 per function (60% reduction from baseline ~15)
- **Coupling**: <5 module dependencies (40% reduction from baseline ~8)
- **LCOM Metric**: >0.7 cohesion
- **Lines of Code**: Expect 50% reduction via extraction to separate components

### Expected Architecture Improvements

1. **Separation of Concerns**:
   - Navigation logic → `WorkspaceRouterDelegate` (new)
   - State management → `NavigationStateNotifier` (new)
   - UI rendering → `WorkspacePage` (refactored, simplified)

2. **Reduced Coupling**:
   - Extract permission checks to `PermissionContextNotifier`
   - Extract view context resolution to `ViewContextResolver`
   - Remove direct Navigator 1.0 push/pop calls

3. **Improved Testability**:
   - Navigator 2.0 allows isolated testing of routing logic
   - StateNotifier enables pure state transition tests
   - Mocking simplified with Riverpod providers

---

## Measurement Tools

- **Flutter Analyze**: `flutter analyze --no-pub`
- **Manual Inspection**: Count import statements, method lengths
- **Line Counter**: `wc -l` command
- **LCOM Calculator**: Manual calculation or IDE plugins (IntelliJ IDEA Metrics)

---

## Validation Plan (Phase 8)

**Task T150-T154**: Code quality review

1. **T150**: Run `flutter analyze` on refactored code
2. **T152**: Review WorkspaceRouterDelegate complexity
3. **T153**: Review NavigationStateNotifier complexity
4. **T154**: Review ViewContextResolver complexity
5. **Compare**: New metrics vs baseline metrics in this file

**Success Criteria**:
- Average complexity reduced by ≥40%
- No functions with complexity >10
- Module coupling <5 for all navigation files

---

## Notes

- This file will be updated with actual measurements after T008.5 completes
- Baseline measurements must be taken BEFORE any refactoring work begins
- Keep this file in version control to track improvement over time
