// Dashboard Nested Iframe Protection
// 防止多次嵌入dashboard页面时出现冲突

(function() {
  'use strict';
  
  // 防止重复初始化
  if (window.dashboardNestedProtectionLoaded) return;
  window.dashboardNestedProtectionLoaded = true;
  
  // 检测是否在嵌套iframe中
  function isNestedIframe() {
    return window.self !== window.top;
  }
  
  // 初始化嵌套保护
  function initNestedProtection() {
    // 如果在嵌套iframe中，禁用冲突功能
    if (isNestedIframe()) {
      console.log('Dashboard nested protection: Running in nested iframe');
      disableNestedConflicts();
    }
    
    // 为dashboard页面添加特殊处理
    if (window.location.pathname.includes('/dashboard/')) {
      handleDashboardPages();
    }
  }
  
  // 禁用嵌套冲突功能
  function disableNestedConflicts() {
    // 禁用全屏功能
    const fullscreenBtns = document.querySelectorAll('.dashboard-iframe-fullscreen-btn, .hextra-iframe-fullscreen-btn');
    fullscreenBtns.forEach(btn => {
      btn.disabled = true;
      btn.title = '嵌套iframe中禁用全屏功能';
      btn.style.opacity = '0.5';
      btn.style.cursor = 'not-allowed';
    });
    
    // 隐藏可能冲突的JavaScript
    if (window.toggleDashboardIframeFullscreen) {
      window.toggleDashboardIframeFullscreen = function() {
        console.warn('Fullscreen disabled in nested iframe');
      };
    }
  }
  
  // 处理dashboard页面
  function handleDashboardPages() {
    // 为多个iframe添加唯一标识
    const iframes = document.querySelectorAll('iframe[src*="dashboard.html"]');
    iframes.forEach((iframe, index) => {
      // 添加唯一标识避免ID冲突
      iframe.id = `dashboard-nested-iframe-${Date.now()}-${index}`;
      
      // 监听iframe加载完成
      iframe.addEventListener('load', function() {
        try {
          // 通知iframe内部禁用冲突功能
          const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
          if (iframeDoc) {
            const style = iframeDoc.createElement('style');
            style.textContent = `
              .dashboard-iframe-fullscreen-btn, .hextra-iframe-fullscreen-btn {
                display: none !important;
              }
            `;
            iframeDoc.head.appendChild(style);
          }
        } catch (e) {
          console.warn('Cannot access iframe content:', e);
        }
      });
    });
  }
  
  // 监听页面消息
  window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'dashboard-nested-check') {
      // 回复嵌套检查
      event.source.postMessage({
        type: 'dashboard-nested-response',
        isNested: isNestedIframe()
      }, event.origin);
    }
  });
  
  // 页面加载完成后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initNestedProtection);
  } else {
    initNestedProtection();
  }
  
  // 暴露全局函数
  window.dashboardNestedProtection = {
    isNestedIframe: isNestedIframe,
    initNestedProtection: initNestedProtection,
    disableNestedConflicts: disableNestedConflicts
  };
  
})();