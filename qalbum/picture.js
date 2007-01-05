// Copyright 2006 Per Bothner

var hidePreamble = uphash.indexOf("scaled-only") > 0;
var up_button_link, prev_button_link, next_button_link;
var scaled = uphash.indexOf("scaled") > 0;

function addStyleRule(sel, spec) {
  var stylesheet = document.styleSheets[0];
  if (stylesheet.insertRule)
    stylesheet.insertRule(sel+" {"+spec+"}", 0);
  else if (stylesheet.addRule)
    stylesheet.addRule(sel, spec);
}
if (scaled) {
  // We want to disable the initial display of the image as it is loaded,
  // before it gets scaled, to avoid (slow) flicker.
  // We add a rule to the dynamic stylesheet to do this.
  // We add the rule using JavaScript since we only want to disable the
  // initial display when JavaScript is enable.
  addStyleRule("img#main-image", "visibility: hidden");
 }

function StyleFixLinks() {
  if (top.slider) {
    if (up_button_link) { 
      up_button_link.setAttribute('onclick',
        "top.location='index.html#slider'");
      up_button_link.href = "index.html"+uphash;
    }
    if (prev_button_link) {
      prev_button_link.setAttribute('onclick',
        "top.slider.sliderSelectId('"+prevId+"');return false;");
      prev_button_link.href = "slider.html#"+prevId;
    }
    if (next_button_link) {
      next_button_link.setAttribute('onclick',
        "top.slider.sliderSelectId('"+nextId+"');return false;");
      next_button_link.href = "slider.html#"+nextId;
    }
  }
  else {
    if (up_button_link)
      up_button_link.href = "index.html"+uphash;
    if (prev_button_link)
      prev_button_link.href = prev_button_link.href.replace("#.*$","")+hash;
    if (next_button_link)
      next_button_link.href = next_button_link.href.replace("#.*$","")+hash;
  }
}

function OnLoad() {
  up_button_link = document.getElementById("up-button");
  prev_button_link = document.getElementById("prev-button");
  next_button_link = document.getElementById("next-button");
  StyleFixLinks();
  var td_nodes = document.getElementsByTagName("td");
  for (var i = td_nodes.length;  --i >= 0; )
    {
      var td_node = td_nodes[i];
      var parent = td_node.parentNode;
      if (td_node.getAttribute("style-button"))
        td_node.parentNode.removeChild(td_node);
    }
  preamble = document.getElementById("preamble");
  if (scaled)
    ScaledLoad();
}
var image, preamble;
function ScaledLoad() {
  var body = preamble.parentNode;
  body.style.overflow = "hidden";
  image = document.getElementById("main-image");
  image.style.position="absolute";
  image.style.bottom="0px";
  image.style.right="0px";
  image.origwidth = image.getAttribute("width");
  image.origheight = image.getAttribute("height");
  image.style.border = "0px";
  preamble.style.position="absolute";
  preamble.style.visibility = hidePreamble ? "hidden" : "visible";
  ScaledResize();
  image.style.visibility = "visible";
}

function ScaledResize() {
  if (! scaled)
    return;
  /* Window size calculation from S5 slides.css. by Eric Meyer. */
  var hSize, vSize;
   if (window.innerHeight) {
          vSize = window.innerHeight;
          hSize = window.innerWidth;
  } else if (document.documentElement.clientHeight) {
          vSize = document.documentElement.clientHeight;
          hSize = document.documentElement.clientWidth;
  } else if (document.body.clientHeight) {
          vSize = document.body.clientHeight;
          hSize = document.body.clientWidth;
  } else {
          vSize = 700;  // assuming 1024x768, minus chrome and such
          hSize = 1024; // these do not account for kiosk mode or Opera Show
  }
  var wscale = hSize /  image.origwidth;
  var hscale = vSize / image.origheight;
  var scale = Math.min(wscale, hscale);
  image.style.width = scale * image.origwidth;
  image.style.height = scale * image.origheight;
}

function handler(e) {
  var event = e ? e : window.event;
  var key = event.keyCode ? event.keyCode : event.which;
  if (event.ctrlKey || event.altKey || event.metaKey) return;
  //if (event.shiftKey) key += 100;
  if (key >= 65 && key <= 90) key += 32; // Needed for Konqueor
  if (key == 32 || key == 34) { // space or page-down
    var body = document.body;
    if (nextId && body.scrollTop+body.clientHeight>=body.scrollHeight)
      key = 110;
    else
      return true;
  }
  if (nextId && key == 110) { // 'n' key
      if (top.slider) {
        top.slider.sliderSelectId(nextId);
        return false;
      }
      location=nextId+style_link+".html"+hash; return true;
  }
  if (key == 33) { // page-up
    var body = document.body;
    if (prevId && body.scrollTop==0)
      key = 112;
    else
      return true;
  }
  if (prevId && key == 112) {
      if (top.slider) {
        top.slider.sliderSelectId(prevId);
        return false;
      }
    location=prevId+style_link+".html"+hash; return true;
  }
  if (key == 117) { location="index.html"+uphash; return true; }
  if (key == 115) { location="slider.html#"+thisId; return true; }
  if (key == 105) { location=thisId+"info.html"; return true; }
  if (key == 108) { location=thisId+"large.html#large-scaled"; return true; }
  if (key == 109) { location=thisId+".html"; return true; }
  if (scaled && key == 104 ) {
    hidePreamble = !hidePreamble;
    preamble.style.visibility = hidePreamble ? "hidden" : "visible";
    if (hash.indexOf("large") > 0)
      hash = hidePreamble ? "#large-scaled-only" : "#large-scaled";
    else
      hash = hidePreamble ? "#medium-scaled-only" : "#medium-scaled";
    uphash = hash;
    location.hash = hash;
    StyleFixLinks();
    return true;
  }
}
document.onkeypress = handler;

function styleChange (element) {
  for (var i = 0; i < element.options.length; i++)
    if (element.options[i].selected) {
      var old_pathname = top.location.pathname;
      var old_hash = top.location.hash;
      var old_scaled = scaled;
      uphash = "#"+element.options[i].value;
      top.location = element.options[i].getAttribute("target");
      scaled = uphash.indexOf("scaled") > 0;
      hash = top.location.hash;
      StyleFixLinks();
      if (old_pathname==top.location.pathname && scaled && ! old_scaled)
        ScaledLoad();
      return;
    }
}

function styleOption(value, target, text) {
  var r = "<option target='"+target+"' value='"+value+"'";
  if (uphash.substring(1)==value) r+=' selected';
  r= r+">"+text+"</option>";
  return r;
}

function WriteStyleMenu () {
  document.write("<td><span class='button'>Style: <select onchange='styleChange(this)'>"
  + styleOption("help", libdir+"/help.html#styles", "Help me choose")
  + styleOption("", thisId+".html", "medium (default)")
  + styleOption("large", thisId+"large.html", "large")
  + styleOption("large-scaled", thisId+"large.html#large-scaled", "large scaled-to-fit")
  + styleOption("large-scaled-only", thisId+"large.html#large-scaled-only", "large scaled, no text")
  + styleOption("medium-scaled", thisId+".html#medium-scaled", "medium scaled-to-fit")
  + styleOption("medium-scaled-only", thisId+".html#medium-scaled-only", "medium scaled, no text")
  + styleOption("slider", "slider.html#"+thisId, "slider")
  + styleOption("info", thisId+"info.html", "information")
  + "</select></span></td>");
}
