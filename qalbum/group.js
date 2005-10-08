document.onkeypress = handler;
var hash = location.hash;
function handler(e) {
  var key = e ? e.which : event.keyCode;
  if (key == 117) { location="../index.html"; return true; }
  return routeEvent(e);
}
function fixLinks() {
  if (hash=="")
    return;
  var links = document.getElementsByTagName("a");
  // FIXME assume all links are to thumbnails.
  for (var i = links.length; --i >= 0; ) {
    var href = links[i].href;
    if (hash=="#info")
      href = href.replace(/[.]html/, "info.html");
    else if (hash=="#large-scaled-only")
      href = href.replace(/[.]html/, "large.html#large-scaled-only");
    else if (hash=="#large-scaled")
      href = href.replace(/[.]html/, "large.html");
    links[i].href = href;
  }
}

