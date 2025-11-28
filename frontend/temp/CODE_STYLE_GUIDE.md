# Code Style Guide

## Language Requirements

### ✅ MUST Use English For:
1. **All user-visible strings**
   - Error messages
   - Exception messages
   - Validation messages
   - Toast notifications
   - Dialog messages
   - Button text
   - Form labels

2. **All code strings**
   - Variable names
   - Function names
   - Class names
   - Constant values
   - Log messages
   - Debug output
   - Mock data values

3. **Documentation strings**
   - Function documentation
   - Class documentation
   - Parameter descriptions

### ✅ Allowed Chinese Usage:
1. **Comments only** (// or /// or /* */)
   - Inline comments explaining logic
   - Section headers in comments
   - TODO comments

### ❌ NEVER Use Chinese For:
- Error messages: `throw Exception('请重试')` ❌
- Return values: `return '操作失败'` ❌
- Variables: `String 错误信息 = ''` ❌
- Mock data: `name: '测试数据'` ❌
- Debug output: `print('调试信息')` ❌

## Examples

### ❌ Wrong:
```dart
if (data.isEmpty) {
  setError('数据为空，请重试');
  throw Exception('加载失败');
}
```

### ✅ Correct:
```dart
// 检查数据是否为空
if (data.isEmpty) {
  setError('Data is empty, please try again');
  throw Exception('Loading failed');
}
```

## Automated Checking

Run the following command to check for Chinese strings:
```bash
dart run tools/check_chinese_strings.dart
```

This will scan all `.dart` files and report any Chinese strings outside of comments.

## Why English Only?

1. **International compatibility** - App can be used globally
2. **Professional standard** - Industry best practice
3. **Team collaboration** - Easier for international teams
4. **Code review** - Easier to review in English
5. **Future i18n** - Ready for proper internationalization
6. **Debugging** - Easier to search and debug issues
