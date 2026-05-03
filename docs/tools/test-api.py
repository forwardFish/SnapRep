#!/usr/bin/env python3
"""
测试脚本：验证头像和训练日历功能
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:3000"

def test_login(email, password):
    """测试登录并返回 token"""
    print(f"\n{'='*60}")
    print(f"测试 1: 登录测试 - {email}")
    print(f"{'='*60}")

    url = f"{BASE_URL}/rest/v1/auth/login"
    payload = {"email": email, "password": password}

    try:
        response = requests.post(url, json=payload)
        print(f"状态码: {response.status_code}")

        if response.status_code == 200 or response.status_code == 201:
            data = response.json()
            print(f"✅ 登录成功！")

            # 检查返回的用户数据
            if 'user' in data:
                user = data['user']
                print(f"\n用户信息:")
                print(f"  - ID: {user.get('id', 'N/A')}")
                print(f"  - Email: {user.get('email', 'N/A')}")
                print(f"  - Name: {user.get('name', 'N/A')}")
                print(f"  - Avatar URL: {user.get('avatarUrl', 'N/A')}")

                if user.get('avatarUrl'):
                    print(f"\n✅ 头像 URL 已生成！")
                    print(f"   URL: {user['avatarUrl']}")
                else:
                    print(f"\n❌ 警告：登录响应中没有返回 avatarUrl")

            return data.get('accessToken')
        else:
            print(f"❌ 登录失败")
            print(f"响应: {response.text}")
            return None
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return None

def test_get_current_user(token):
    """测试获取当前用户信息（检查头像URL）"""
    print(f"\n{'='*60}")
    print(f"测试 2: 获取当前用户信息（/rest/v1/auth/me）")
    print(f"{'='*60}")

    url = f"{BASE_URL}/rest/v1/auth/me"
    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.get(url, headers=headers)
        print(f"状态码: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"✅ 获取用户信息成功！")
            print(f"\n用户信息:")
            print(f"  - ID: {data.get('id', 'N/A')}")
            print(f"  - Email: {data.get('email', 'N/A')}")
            print(f"  - Name: {data.get('name', 'N/A')}")
            print(f"  - Avatar URL: {data.get('avatarUrl', 'N/A')}")

            if data.get('avatarUrl'):
                print(f"\n✅ 头像 URL 已返回！")
                print(f"   URL: {data['avatarUrl']}")

                # 测试头像 URL 是否可访问
                try:
                    avatar_response = requests.get(data['avatarUrl'], timeout=5)
                    if avatar_response.status_code == 200:
                        print(f"   ✅ 头像 URL 可访问（状态码: {avatar_response.status_code}）")
                    else:
                        print(f"   ⚠️ 头像 URL 返回状态码: {avatar_response.status_code}")
                except Exception as e:
                    print(f"   ⚠️ 无法访问头像 URL: {e}")
            else:
                print(f"\n❌ 问题：API 没有返回 avatarUrl")

            return data.get('id')
        else:
            print(f"❌ 获取用户信息失败")
            print(f"响应: {response.text}")
            return None
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return None

def test_get_workout_sessions(token, user_id):
    """测试获取训练会话（检查训练日历数据）"""
    print(f"\n{'='*60}")
    print(f"测试 3: 获取训练会话（/api/v1/users/{user_id}/sessions）")
    print(f"{'='*60}")

    url = f"{BASE_URL}/api/v1/users/{user_id}/sessions"
    headers = {"Authorization": f"Bearer {token}"}
    params = {"status": "COMPLETED", "limit": 100}

    try:
        response = requests.get(url, headers=headers, params=params)
        print(f"状态码: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"✅ 获取训练会话成功！")

            if 'data' in data:
                sessions = data['data']
                print(f"\n训练会话数量: {len(sessions)}")

                if len(sessions) == 0:
                    print(f"ℹ️ 用户没有完成的训练记录（这是正常的，说明使用了真实数据）")
                    print(f"✅ Workout Calendar 应该显示为空（不再显示 mock 数据）")
                else:
                    print(f"\n最近的训练会话:")
                    for i, session in enumerate(sessions[:5], 1):
                        completed_at = session.get('completedAt') or session.get('completed_at', 'N/A')
                        print(f"  {i}. 完成时间: {completed_at}")

                    # 提取唯一的训练日期
                    workout_dates = set()
                    for session in sessions:
                        completed_at = session.get('completedAt') or session.get('completed_at')
                        if completed_at:
                            date_only = completed_at.split('T')[0]
                            workout_dates.add(date_only)

                    print(f"\n唯一训练日期数量: {len(workout_dates)}")
                    print(f"训练日期: {sorted(workout_dates)}")
            else:
                print(f"⚠️ 响应格式异常: {data}")

            return True
        else:
            print(f"❌ 获取训练会话失败")
            print(f"响应: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 请求失败: {e}")
        return False

def main():
    print(f"\n{'#'*60}")
    print(f"# SnapRep API 测试 - 头像和训练日历功能")
    print(f"# 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'#'*60}")

    # 测试账号
    email = "forwardfish1309001@163.com"
    password = "12345678"  # 请替换为实际密码

    # 测试 1: 登录
    token = test_login(email, password)
    if not token:
        print(f"\n❌ 登录失败，无法继续测试")
        return

    # 测试 2: 获取当前用户信息（头像）
    user_id = test_get_current_user(token)
    if not user_id:
        print(f"\n❌ 无法获取用户信息，无法继续测试")
        return

    # 测试 3: 获取训练会话（训练日历）
    test_get_workout_sessions(token, user_id)

    # 总结
    print(f"\n{'='*60}")
    print(f"测试总结")
    print(f"{'='*60}")
    print(f"✅ 所有测试完成")
    print(f"\n请在前端应用中验证:")
    print(f"  1. 登录后头像是否显示用户首字母")
    print(f"  2. Workout Calendar 是否显示真实数据（当前应该为空）")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    main()
