/* ==========================================================================
   Hacker News Dark — content script (runs at document_start)

   There are exactly two states, as requested:

     invert = false  ->  theme matches the system appearance
     invert = true   ->  theme is the opposite of the system appearance

   Because the stored state is *relative* to the system, "automatically
   switches" falls out for free: when macOS/Windows flips at sunset, so does
   HN, in whichever direction the user last chose.

   The effective theme is written to <html data-hn-theme="dark|light">, which
   is the single gate every rule in hn-dark.css hangs off.
   ========================================================================== */

(function () {
  "use strict";

  var CACHE_KEY = "hnDark:invert"; // localStorage mirror, read synchronously
  var STORE_KEY = "invert"; // chrome.storage.sync, the source of truth
  var LINK_ID = "hn-theme-toggle";

  var media = window.matchMedia("(prefers-color-scheme: dark)");
  var invert = readCache();

  /* ---------------------------------------------------------------- state */

  // chrome.storage is async, which would mean a flash of the wrong theme on
  // every page load. localStorage is synchronous and same-origin, so it acts
  // as the fast path and chrome.storage reconciles a tick later.
  function readCache() {
    try {
      return window.localStorage.getItem(CACHE_KEY) === "1";
    } catch (e) {
      return false;
    }
  }

  function writeCache(value) {
    try {
      window.localStorage.setItem(CACHE_KEY, value ? "1" : "0");
    } catch (e) {
      /* private mode / storage disabled — chrome.storage still works */
    }
  }

  function effectiveTheme() {
    return media.matches !== invert ? "dark" : "light";
  }

  /* ---------------------------------------------------------------- apply */

  function apply() {
    var theme = effectiveTheme();
    var root = document.documentElement;

    if (root) {
      root.setAttribute("data-hn-theme", theme);
    } else {
      // Extremely early in the parse the root element may not exist yet.
      var observer = new MutationObserver(function () {
        if (document.documentElement) {
          observer.disconnect();
          document.documentElement.setAttribute("data-hn-theme", theme);
        }
      });
      observer.observe(document, { childList: true });
    }

    decorateLink(theme);
  }

  function toggle() {
    invert = !invert;
    if (document.documentElement) {
      document.documentElement.classList.add("hn-anim");
    }
    writeCache(invert);
    apply();
    try {
      chrome.storage.sync.set({ invert: invert });
    } catch (e) {
      /* extension context torn down (e.g. just reloaded) — cache still holds */
    }
  }

  apply();

  // Reconcile with the synced value, and follow it when another tab or
  // another device changes it.
  try {
    chrome.storage.sync.get({ invert: false }, function (stored) {
      if (chrome.runtime.lastError) return;
      if (!!stored.invert !== invert) {
        invert = !!stored.invert;
        writeCache(invert);
        apply();
      }
    });

    chrome.storage.onChanged.addListener(function (changes, area) {
      if (area !== "sync" || !changes[STORE_KEY]) return;
      var next = !!changes[STORE_KEY].newValue;
      if (next === invert) return;
      invert = next;
      writeCache(invert);
      apply();
    });
  } catch (e) {
    /* no storage access: fall back to the localStorage mirror alone */
  }

  // The whole point of storing "relative to system": follow the OS at sunset.
  if (media.addEventListener) {
    media.addEventListener("change", apply);
  } else if (media.addListener) {
    media.addListener(apply);
  }

  /* ----------------------------------------------------------- toolbar link */

  function decorateLink(theme) {
    var link = document.getElementById(LINK_ID);
    if (!link) return;
    link.title =
      "Theme: " +
      theme +
      " — " +
      (invert ? "opposite of system" : "matching system") +
      ". Click to switch.";
    link.setAttribute("aria-label", "Switch theme (currently " + theme + ")");
  }

  function insertLink() {
    if (document.getElementById(LINK_ID)) return;

    // The header's right-hand cell: "login", or "me (karma) | logout".
    var tops = document.querySelectorAll("#hnmain span.pagetop");
    var bar = tops[tops.length - 1];
    if (!bar) return;

    var link = document.createElement("a");
    link.id = LINK_ID;
    link.href = "#";
    link.textContent = "theme";
    link.addEventListener("click", function (event) {
      event.preventDefault();
      toggle();
    });

    // Sit immediately right of logout (or login when signed out).
    var after =
      bar.querySelector('a[href^="logout"]') ||
      bar.querySelector("#logout") ||
      bar.querySelector('a[href^="login"]') ||
      bar.lastElementChild;

    // HN separates header links with non-breaking spaces around a pipe.
    var separator = document.createTextNode("\u00a0|\u00a0");
    if (after && after.parentNode === bar) {
      bar.insertBefore(separator, after.nextSibling);
      bar.insertBefore(link, separator.nextSibling);
    } else {
      bar.appendChild(separator);
      bar.appendChild(link);
    }

    decorateLink(effectiveTheme());
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", insertLink, { once: true });
  } else {
    insertLink();
  }
})();
