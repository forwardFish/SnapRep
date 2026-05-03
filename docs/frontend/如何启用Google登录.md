# 如何启用 Google 登录

## 问题描述

当前 Google 登录功能已经实现，但是 Supabase 项目中没有启用 Google OAuth 提供商，导致出现错误：

```
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

## 解决步骤

### 步骤 1：配置 Google Cloud Console

#### 1.1 创建 Google Cloud 项目

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 如果没有项目，点击 **New Project** 创建一个新项目
   - 项目名称：`SnapRep` 或其他名称
   - 组织：选择你的组织（或留空）
3. 等待项目创建完成

#### 1.2 启用 Google+ API

1. 在左侧菜单中，选择 **APIs & Services** → **Library**
2. 搜索 **Google+ API**
3. 点击 **Enable**（启用）

#### 1.3 创建 OAuth 2.0 凭据

1. 在左侧菜单中，选择 **APIs & Services** → **Credentials**（凭据）
2. 点击 **Create Credentials** → **OAuth 2.0 Client ID**
3. 如果提示配置 OAuth 同意屏幕，点击 **Configure Consent Screen**：
   - User Type: 选择 **External**（外部）
   - App name: `SnapRep`
   - User support email: 你的邮箱
   - Developer contact email: 你的邮箱
   - 点击 **Save and Continue**
   - Scopes: 点击 **Save and Continue**（使用默认）
   - Test users: 可以添加测试用户，或直接 **Save and Continue**
   - 点击 **Back to Dashboard**

4. 返回 Credentials 页面，再次点击 **Create Credentials** → **OAuth 2.0 Client ID**
5. 配置 OAuth 客户端：
   - **Application type**: 选择 **Web application**（Web 应用）
   - **Name**: `SnapRep Web Client`
   - **Authorized JavaScript origins**: 添加以下 URI
     ```
     https://tvjcmleckqovnieuexgu.supabase.co
     ```
   - **Authorized redirect URIs**: 添加以下 URI
     ```
     https://tvjcmleckqovnieuexgu.supabase.co/auth/v1/callback
     ```
6. 点击 **Create**

7. 保存凭据信息：
   - **Client ID**: 形如 `123456789-abcdefg.apps.googleusercontent.com`
   - **Client Secret**: 形如 `GOCSPX-xxxxxxxxxxxxx`
   - 请妥善保管这些信息！

### 步骤 2：配置 Supabase

#### 2.1 登录 Supabase Dashboard

1. 访问 [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. 登录你的账号
3. 选择你的项目（项目 ID：`tvjcmleckqovnieuexgu`）

#### 2.2 启用 Google 提供商

1. 在左侧菜单中，点击 **Authentication**（认证）图标 🔐
2. 点击顶部的 **Providers** 标签页
3. 在提供商列表中找到 **Google**
4. 点击 Google 提供商进入配置页面
5. 配置以下信息：
   - **Enable Sign in with Google**: 打开开关 ✅
   - **Client ID (for OAuth)**: 粘贴从 Google Cloud Console 获取的 Client ID
   - **Client Secret (for OAuth)**: 粘贴从 Google Cloud Console 获取的 Client Secret
   - **Authorized Client IDs**: 留空（可选）
   - **Skip nonce check**: 保持默认（不勾选）
6. 点击 **Save** 保存配置

#### 2.3 验证配置

保存后，Supabase 会显示：
- **Callback URL (for OAuth)**: `https://tvjcmleckqovnieuexgu.supabase.co/auth/v1/callback`
- 确保这个 URL 已经添加到 Google Cloud Console 的 **Authorized redirect URIs**

### 步骤 3：启用前端 Google 登录按钮

编辑文件：`frontend/lib/features/auth/screens/google_login_page.dart`

找到这一行：
```dart
static const bool _enableGoogleLogin = false;
```

改为：
```dart
static const bool _enableGoogleLogin = true;
```

保存文件，重新运行 Flutter 应用。

### 步骤 4：测试 Google 登录

1. 打开 SnapRep 应用
2. 进入 Profile 页面
3. 点击 **Login** 按钮
4. 在登录页面，点击 **Continue with Google** 按钮
5. 应该会打开浏览器，跳转到 Google 登录页面
6. 选择你的 Google 账号并授权
7. 授权成功后，会跳转回应用，自动登录

## 常见问题

### Q1: 点击 Google 登录后显示 "redirect_uri_mismatch" 错误

**原因**: Google Cloud Console 中配置的 Redirect URI 不正确。

**解决方案**:
1. 检查 Google Cloud Console 的 **Authorized redirect URIs** 是否正确
2. 确保 URI 为：`https://tvjcmleckqovnieuexgu.supabase.co/auth/v1/callback`
3. 注意：URI 必须**完全匹配**，包括 `https://`、域名和路径

### Q2: 显示 "Unsupported provider: provider is not enabled"

**原因**: Supabase 项目中没有启用 Google 提供商，或配置未保存。

**解决方案**:
1. 确认 Supabase Dashboard 中 Google 提供商的开关已打开
2. 确认已点击 **Save** 保存配置
3. 等待 1-2 分钟让配置生效
4. 清除浏览器缓存后重试

### Q3: Google 登录后没有跳转回应用

**原因**: Deep Link 配置问题（移动应用）或浏览器重定向问题。

**解决方案**:
1. 对于 Web 应用：无需额外配置
2. 对于移动应用：需要配置 Deep Link
   - iOS: 配置 Associated Domains
   - Android: 配置 Intent Filter

## MVP 阶段的临时方案

如果你现在不想配置 Google OAuth（配置较复杂），可以：

1. **保持 `_enableGoogleLogin = false`**（默认设置）
2. **只使用邮箱密码登录**
3. 后续有需要时再启用 Google 登录

邮箱密码登录已经完全可用，功能包括：
- ✅ 邮箱密码注册
- ✅ 邮箱密码登录
- ✅ 密码可见性切换
- ✅ 表单验证
- ✅ 错误处理

## 总结

启用 Google 登录需要两个配置：
1. **Google Cloud Console**: 创建 OAuth 客户端，获取 Client ID 和 Secret
2. **Supabase Dashboard**: 启用 Google 提供商，填入 Client ID 和 Secret

配置完成后，将 `_enableGoogleLogin` 改为 `true` 即可启用 Google 登录按钮。

**如果暂时不需要 Google 登录，保持 `_enableGoogleLogin = false`，使用邮箱密码登录即可。**
