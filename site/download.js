// Fills the Download section from the latest published GitHub Release on
// layer5io/blowhorn-site. Drafts and prereleases are never "latest", so the
// placeholder stays until the first stable release is published.
(function () {
  "use strict";

  var card = document.getElementById("download-status");
  if (!card || !window.fetch) {
    return;
  }
  var repo = card.getAttribute("data-repo");
  var alias = card.getAttribute("data-asset");

  function el(tag, text, attrs) {
    var node = document.createElement(tag);
    if (text) {
      node.textContent = text;
    }
    Object.keys(attrs || {}).forEach(function (key) {
      node.setAttribute(key, attrs[key]);
    });
    return node;
  }

  fetch("https://api.github.com/repos/" + repo + "/releases/latest", {
    headers: { Accept: "application/vnd.github+json" },
  })
    .then(function (res) {
      return res.ok ? res.json() : null;
    })
    .then(function (release) {
      if (!release || !Array.isArray(release.assets)) {
        return;
      }
      var dmg = release.assets.find(function (a) {
        return a.name === alias;
      }) || release.assets.find(function (a) {
        return /\.dmg$/i.test(a.name);
      });
      if (!dmg) {
        return;
      }
      var sums = release.assets.find(function (a) {
        return a.name === "SHA256SUMS.txt";
      });

      card.textContent = "";
      var cta = el("p");
      cta.appendChild(el("a", "Download Blowhorn " + release.tag_name + " for macOS", {
        class: "button",
        href: "https://github.com/" + repo + "/releases/latest/download/" + dmg.name,
      }));
      card.appendChild(cta);

      var meta = el("p", null, { class: "muted" });
      meta.appendChild(document.createTextNode(dmg.name + " \u00b7 " + Math.round(dmg.size / 1048576) + " MB \u00b7 "));
      meta.appendChild(el("a", "Release notes", { href: release.html_url }));
      if (sums) {
        meta.appendChild(document.createTextNode(" \u00b7 "));
        meta.appendChild(el("a", "SHA256SUMS.txt", { href: sums.browser_download_url }));
      }
      card.appendChild(meta);
    })
    .catch(function () {
      // Keep the static placeholder on network or rate-limit errors.
    });
})();
