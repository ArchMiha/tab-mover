// Native messaging host name (must match host manifest)
const HOST_NAME = 'com.tabmover.host';

// Listen for keyboard shortcut command
chrome.commands.onCommand.addListener(async (command) => {
  if (command === 'move-tab-to-instance') {
    await moveActiveTabToNewInstance();
  }
});

// Also allow activation via extension icon click
chrome.action.onClicked.addListener(async (tab) => {
  await moveActiveTabToNewInstance();
});

async function moveActiveTabToNewInstance() {
  try {
    // Get the active tab in the current window
    const [tab] = await chrome.tabs.query({
      active: true,
      currentWindow: true
    });

    if (!tab) {
      showError('No active tab found');
      return;
    }

    // Validate URL (cannot move chrome:// or internal pages)
    if (!tab.url ||
        tab.url.startsWith('chrome://') ||
        tab.url.startsWith('chrome-extension://') ||
        tab.url.startsWith('about:') ||
        tab.url.startsWith('edge://') ||
        tab.url.startsWith('brave://')) {
      showError('Cannot move browser internal pages');
      return;
    }

    // Send message to native host
    const response = await sendNativeMessage({
      action: 'open_in_new_instance',
      url: tab.url,
      title: tab.title || 'Untitled'
    });

    if (response.success) {
      // Close the original tab
      await chrome.tabs.remove(tab.id);
    } else {
      showError(response.error || 'Failed to open new instance');
    }

  } catch (error) {
    console.error('Error moving tab:', error);
    showError(error.message || 'Unknown error occurred');
  }
}

function sendNativeMessage(message) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendNativeMessage(HOST_NAME, message, (response) => {
      if (chrome.runtime.lastError) {
        reject(new Error(chrome.runtime.lastError.message));
      } else if (response) {
        resolve(response);
      } else {
        reject(new Error('No response from native host'));
      }
    });
  });
}

function showError(message) {
  // Set badge to indicate error
  chrome.action.setBadgeText({ text: '!' });
  chrome.action.setBadgeBackgroundColor({ color: '#F44336' });

  // Show notification
  chrome.notifications.create({
    type: 'basic',
    iconUrl: 'icons/icon128.png',
    title: 'Tab Mover - Error',
    message: message
  });

  // Clear badge after 3 seconds
  setTimeout(() => {
    chrome.action.setBadgeText({ text: '' });
  }, 3000);
}
