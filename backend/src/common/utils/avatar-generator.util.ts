/**
 * Avatar Generator Utility
 * 为没有头像的用户生成美观的默认头像
 *
 * 支持多种风格：
 * 1. DiceBear API - 专业的头像生成服务
 * 2. UI Avatars - 简单的文字头像
 * 3. 渐变色首字母头像（本地生成）
 */

export class AvatarGenerator {
  /**
   * 根据用户名生成头像 URL
   * 优先使用 DiceBear 的 initials 风格（Material Design 风格）
   */
  static generateAvatarUrl(name: string, email?: string): string {
    if (!name || name.trim() === '') {
      name = email ? email.split('@')[0] : 'User';
    }

    const initials = this.getInitials(name);
    const colorIndex = this.getColorIndex(name);

    // 方案1: DiceBear Initials (推荐 - Material Design 3 风格)
    // https://www.dicebear.com/styles/initials/
    return this.generateDiceBearUrl(initials, colorIndex);

    // 方案2: UI Avatars (备用)
    // return this.generateUIAvatarsUrl(initials, colorIndex);

    // 方案3: 本地 SVG 数据 URL (如果需要完全本地化)
    // return this.generateLocalSvgDataUrl(initials, colorIndex);
  }

  /**
   * 获取用户名的首字母（1-2个字符）
   */
  private static getInitials(name: string): string {
    const parts = name.trim().split(/\s+/);

    if (parts.length >= 2) {
      // 取前两个单词的首字母：John Doe → JD
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      // 单个单词取前1-2个字符：Alice → A, 林 → 林
      const firstWord = parts[0];
      // 中文只取1个字符，英文取前2个
      const isChinese = /[\u4e00-\u9fa5]/.test(firstWord);
      return isChinese
        ? firstWord[0]
        : firstWord.substring(0, Math.min(2, firstWord.length)).toUpperCase();
    }
  }

  /**
   * 根据名字生成一致的颜色索引（0-25）
   * 使用简单的哈希算法确保同名用户颜色一致
   */
  private static getColorIndex(name: string): number {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return Math.abs(hash) % 26;
  }

  /**
   * 方案1: 使用 DiceBear API 生成头像
   *
   * DiceBear 是一个开源的头像生成服务，提供多种风格
   * 文档: https://www.dicebear.com/
   *
   * @param initials 用户首字母
   * @param colorIndex 颜色索引 (0-25)
   * @returns 头像 URL
   */
  private static generateDiceBearUrl(initials: string, colorIndex: number): string {
    const colors = [
      // Material Design 3 色板 - 柔和渐变色
      'amber', 'blue', 'blueGrey', 'brown', 'cyan',
      'deepOrange', 'deepPurple', 'green', 'grey', 'indigo',
      'lightBlue', 'lightGreen', 'lime', 'orange', 'pink',
      'purple', 'red', 'teal', 'yellow', 'violet',
      'emerald', 'fuchsia', 'rose', 'sky', 'stone', 'zinc'
    ];

    const selectedColor = colors[colorIndex];

    // DiceBear Initials Style with modern gradient
    // 参数说明:
    // - seed: 用作生成的种子（确保一致性）
    // - backgroundColor: 背景颜色
    // - fontSize: 文字大小 (相对于画布大小的百分比)
    // - fontWeight: 字体粗细
    // - radius: 圆角半径 (50 = 圆形)
    const params = new URLSearchParams({
      seed: initials,
      backgroundColor: selectedColor,
      fontSize: '40',
      fontWeight: '600',
      radius: '50',
      scale: '80',
    });

    return `https://api.dicebear.com/7.x/initials/svg?${params.toString()}`;
  }

  /**
   * 方案2: 使用 UI Avatars API
   *
   * 简单可靠的文字头像服务
   * 文档: https://ui-avatars.com/
   *
   * @param initials 用户首字母
   * @param colorIndex 颜色索引
   * @returns 头像 URL
   */
  private static generateUIAvatarsUrl(initials: string, colorIndex: number): string {
    const colorPairs = [
      // [背景色, 文字色] - 确保高对比度
      ['FF6B6B', 'FFFFFF'], // 红色
      ['4ECDC4', 'FFFFFF'], // 青色
      ['45B7D1', 'FFFFFF'], // 蓝色
      ['96CEB4', 'FFFFFF'], // 绿色
      ['FFEAA7', '2D3436'], // 黄色
      ['DFE6E9', '2D3436'], // 灰色
      ['FD79A8', 'FFFFFF'], // 粉色
      ['A29BFE', 'FFFFFF'], // 紫色
      ['FD7272', 'FFFFFF'], // 浅红
      ['54A0FF', 'FFFFFF'], // 天蓝
      ['48DBFB', 'FFFFFF'], // 青蓝
      ['1DD1A1', 'FFFFFF'], // 翠绿
      ['FFC048', 'FFFFFF'], // 橙色
      ['EE5A6F', 'FFFFFF'], // 玫红
      ['C44569', 'FFFFFF'], // 深红
      ['786FA6', 'FFFFFF'], // 靛色
      ['F8A5C2', 'FFFFFF'], // 樱粉
      ['63CDDA', 'FFFFFF'], // 水蓝
      ['EA8685', 'FFFFFF'], // 珊瑚
      ['596275', 'FFFFFF'], // 石板灰
      ['574B90', 'FFFFFF'], // 深紫
      ['F19066', 'FFFFFF'], // 橘色
      ['546DE5', 'FFFFFF'], // 宝蓝
      ['E66767', 'FFFFFF'], // 砖红
      ['303952', 'FFFFFF'], // 深灰
      ['3C6382', 'FFFFFF'], // 钢蓝
    ];

    const [bgColor, textColor] = colorPairs[colorIndex];

    // UI Avatars 参数
    const params = new URLSearchParams({
      name: initials,
      background: bgColor,
      color: textColor,
      size: '200',
      bold: 'true',
      rounded: 'true',
      format: 'svg',
    });

    return `https://ui-avatars.com/api/?${params.toString()}`;
  }

  /**
   * 方案3: 生成本地 SVG Data URL
   *
   * 优点: 完全本地化，无需依赖外部服务
   * 缺点: 需要前端额外处理 SVG
   *
   * @param initials 用户首字母
   * @param colorIndex 颜色索引
   * @returns SVG Data URL
   */
  private static generateLocalSvgDataUrl(initials: string, colorIndex: number): string {
    const gradients = [
      ['#FF6B6B', '#EE5A6F'], // 红色渐变
      ['#4ECDC4', '#44A08D'], // 青色渐变
      ['#45B7D1', '#3498DB'], // 蓝色渐变
      ['#96CEB4', '#7FB069'], // 绿色渐变
      ['#FFEAA7', '#FDCB6E'], // 黄色渐变
      ['#DFE6E9', '#B2BEC3'], // 灰色渐变
      ['#FD79A8', '#F093FB'], // 粉色渐变
      ['#A29BFE', '#6C5CE7'], // 紫色渐变
      ['#FD7272', '#C44569'], // 深红渐变
      ['#54A0FF', '#2E86DE'], // 天蓝渐变
      ['#48DBFB', '#0ABDE3'], // 青蓝渐变
      ['#1DD1A1', '#10AC84'], // 翠绿渐变
      ['#FFC048', '#F79F1F'], // 橙色渐变
      ['#EE5A6F', '#C44569'], // 玫红渐变
      ['#786FA6', '#574B90'], // 靛色渐变
      ['#F8A5C2', '#F78FB3'], // 樱粉渐变
      ['#63CDDA', '#3DC1D3'], // 水蓝渐变
      ['#EA8685', '#D76C6C'], // 珊瑚渐变
      ['#596275', '#303952'], // 石板灰渐变
      ['#574B90', '#474787'], // 深紫渐变
      ['#F19066', '#E77F67'], // 橘色渐变
      ['#546DE5', '#3F51B5'], // 宝蓝渐变
      ['#E66767', '#C44569'], // 砖红渐变
      ['#303952', '#2C3A47'], // 深灰渐变
      ['#3C6382', '#2C3E50'], // 钢蓝渐变
      ['#6C5CE7', '#A29BFE'], // 紫罗兰渐变
    ];

    const [color1, color2] = gradients[colorIndex];

    const svg = `
      <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="grad${colorIndex}" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:${color1};stop-opacity:1" />
            <stop offset="100%" style="stop-color:${color2};stop-opacity:1" />
          </linearGradient>
        </defs>
        <circle cx="100" cy="100" r="100" fill="url(#grad${colorIndex})" />
        <text x="50%" y="50%"
              text-anchor="middle"
              dy=".35em"
              font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
              font-size="70"
              font-weight="600"
              fill="white">${initials}</text>
      </svg>
    `.trim();

    // 编码为 Data URL
    const encoded = Buffer.from(svg).toString('base64');
    return `data:image/svg+xml;base64,${encoded}`;
  }
}
