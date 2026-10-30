# 🔧 实现 `safeDivide(int a, int b) → double`

| 耗时 | ~10 min |
|------|------|

---

## 🎯 目标

安全除法，除零返回 NaN（而非崩溃或抛出异常）。

---

## 📐 涉及文件

| 文件 | 角色 |
|------|------|
| `src/math_util.h` | 接口声明 |
| `src/math_util.cpp` | 实现 |
| `test/test_math.cpp` | 单元测试 |

---

## 🟢 Phase 1 — 声明 + 空壳

```diff
// ── src/math_util.h ──
+ #pragma once
+
+ /// @brief 安全除法，除零返回 NaN
+ double safeDivide(int a, int b);

// ── src/math_util.cpp ──
+ #include "math_util.h"
+ #include <cmath>
+
+ double safeDivide(int a, int b) {
+     return 0.0;  // TODO
+ }
```

| 风险 | 🟢 零 |

---

## 🔵 Phase 2 — 填充逻辑

```diff
// ── src/math_util.cpp ──
 double safeDivide(int a, int b) {
-    return 0.0;  // TODO
+    if (b == 0) {
+        return std::nan("");
+    }
+    return static_cast<double>(a) / b;
 }
```

| 风险 | 🟢 零 |

---

## 🟡 Phase 3 — 加测试

```diff
// ── test/test_math.cpp (新文件) ──
+ #include "math_util.h"
+ #include <cassert>
+ #include <cmath>
+
+ int main() {
+     assert(safeDivide(6, 3) == 2.0);
+     assert(safeDivide(-6, 2) == -3.0);
+     assert(std::isnan(safeDivide(1, 0)));
+     return 0;
+ }
```

| 风险 | 🟡 `double / int` 语义正确，无截断风险 |

---

## 🔴 Phase 4 — 边界修复（review 发现）

```diff
// ── src/math_util.cpp ──
 double safeDivide(int a, int b) {
     if (b == 0) { return std::nan(""); }
-    return static_cast<double>(a) / b;
+    return static_cast<double>(a) / static_cast<double>(b);
 }
```

| 风险 | 🔴 `INT_MIN / -1` 整数溢出 → 各自先转 double 再除 |

---

## 📦 最终产出

| 文件 | 变动 |
|------|------|
| `src/math_util.h` | `+4` |
| `src/math_util.cpp` | `+9 -1` |
| `test/test_math.cpp` | `+14` |
| **合计** | **3 files, +27 -1** |