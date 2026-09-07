/* ==========================================================================
   Assertions for the smoke test.

   Runs in the page, after content.js has themed it, and writes its verdict
   into <pre id="hn-test-results"> so the runner can read it back out of
   --dump-dom. Each fixture declares which checks apply via
   window.__HN_TEST_FIXTURE, set by the runner.

   The colors below are the ones that would break silently: news.css and
   yc.css both paint values that outrank, or are never reached by, the
   obvious selector, so a plausible-looking edit can leave text the same
   color as its background with nothing to see in the diff.
   ========================================================================== */

(function () {
  "use strict";

  /* content.js inserts the header link on DOMContentLoaded, which has not
     fired yet for a script at the end of <body>. Wait for load, or the link
     assertions measure the page a moment too early. */
  function ready(fn) {
    if (document.readyState === "complete") fn();
    else window.addEventListener("load", fn, { once: true });
  }

  ready(function () {

    var CANVAS = "rgb(18, 18, 18)"; // --hn-canvas
    var SURFACE = "rgb(26, 26, 26)"; // --hn-surface
    var FG = "rgb(224, 224, 224)"; // --hn-fg
    var DIM = "rgb(130, 130, 130)"; // --hn-fg-dim, HN's own #828282

    var results = [];

    function check(name, actual, expected) {
      var ok = actual === expected;
      results.push((ok ? "PASS " : "FAIL ") + name + (ok ? "" : " -- got " + actual + ", want " + expected));
    }

    function color(selector, property) {
      var el = document.querySelector(selector);
      if (!el) return "MISSING(" + selector + ")";
      return getComputedStyle(el)[property || "color"];
    }

    var fixture = window.__HN_TEST_FIXTURE;

    /* The gate every rule hangs off. If this is wrong nothing else means much. */
    check("theme attribute is dark", document.documentElement.getAttribute("data-hn-theme"), "dark");

    if (fixture === "news") {
      check("body background", color("body", "backgroundColor"), CANVAS);
      check("#hnmain background", color("#hnmain", "backgroundColor"), SURFACE);

      /* a:link at the gated specificity — the primary text color. */
      check("story title", color(".titleline a"), FG);

      /* The specificity tax: news.css paints these with one-class selectors
         (.subtext a:link, .comhead a:link) that the gated base rule outranks.
         If section 4 ever goes missing, every one of these jumps to FG. */
      check("username in subline", color(".subtext a.hnuser"), DIM);
      check("age link", color(".subtext .age a"), DIM);
      check("site domain", color(".sitebit a"), DIM);
      check("More link", color("a.morelink"), FG);

      /* The top bar is left as HN ships it: black on orange, white when
         selected. The same base a:link rule would repaint it otherwise. */
      check("top bar link", color(".pagetop a[href='newest']"), "rgb(0, 0, 0)");

      /* content.js, not the stylesheet: the link it inserts into the header. */
      var toggle = document.getElementById("hn-theme-toggle");
      check("theme link inserted", toggle ? toggle.textContent : "MISSING", "theme");
      check(
        "theme link is in the header",
        toggle && toggle.closest("span.pagetop") ? "yes" : "no",
        "yes"
      );
    }

    if (fixture === "item") {
      /* Comment bodies take their color from the c00 class, not .commtext. */
      check("comment text", color(".commtext.c00"), FG);
      check("comment header", color(".comhead a.hnuser"), DIM);
      check("reply link", color(".reply a"), FG);
    }

    if (fixture === "poll") {
      /* <font color="#000000"> is a declaration on the font element itself, so
         td { color:#828282 } never reaches it and the text really is black. */
      check("poll option", color("td.comment font[color]"), FG);
    }

    if (fixture === "guidelines") {
      /* yc.css sets no color on the body text at all, so color-scheme: dark
         leaves it white — which is only readable once the panel is dark too. */
      check("doc page panel", color("td[bgcolor='#fafaf0']", "backgroundColor"), SURFACE);
      check("doc page bold", color("td[bgcolor='#fafaf0'] b"), FG);
    }

    if (fixture === "light") {
      /* The other half of the promise: in light mode the extension adds
         nothing, so HN's own cream and black come back untouched. */
      results = []; // the dark-attribute check above does not apply here
      check("theme attribute is light", document.documentElement.getAttribute("data-hn-theme"), "light");
      check("#hnmain is HN's cream", color("#hnmain", "backgroundColor"), "rgb(246, 246, 239)");
      check("story title is HN's black", color(".titleline a"), "rgb(0, 0, 0)");
      check("username is HN's gray", color(".subtext a.hnuser"), DIM);
    }

    var pre = document.createElement("pre");
    pre.id = "hn-test-results";
    pre.textContent = results.join("\n");
    document.body.appendChild(pre);
  });
})();
