declare xmlspace preserve;
declare variable $libdir external;
(:
declare namespace exif-extractor = "class:com.drew.imaging.exif.ExifExtractor"
declare namespace exif-loader = "class:com.drew.imaging.exif.ExifLoader"
declare namespace ImageInfo = "class:com.drew.imaging.exif.ImageInfo"
:)
declare variable $nl := "&#10;";

declare function local:make-img($picture, $scale, $class) {
  <img class="{$class}" src="{$picture}"
    width="{number($picture/@width) * $scale}"
    height="{number($picture/@height) * $scale}"/>
};

declare function local:make-main-img($picture, $scale) {
  <img class="main" id="main-image" src="{$picture}"
    width="{number($picture/@width) * $scale}"
    height="{number($picture/@height) * $scale}"/>
};

declare function local:make-thumbnail($pic) {
  if ($pic/small-image) then
    local:make-img($pic/small-image, 1.0, "thumb")
  else if ($pic/image) then
    local:make-img($pic/image, 0.5, "thumb")
  else if ($pic/full-image) then
    local:make-img($pic/full-image, 0.2, "thumb")
  else
  ( "(missing small-image)", string($pic), ")" )
};

declare function local:style-link($style) {
  if ($style="full") then "large" else $style
};

declare function local:make-link($picture-name, $style, $text) {
  <a class="button" href="{$picture-name}{local:style-link($style)}.html" onclick='OnClick("{$picture-name}")'>{$text}</a>
};

declare function local:format-row($row) {
  "&#10;  ", (: emit a newline for readabilty :)
  <table width="90%" class="row"><tr>{
  for $pic in $row return
  <td>
   <table bgcolor="black" cellpadding="0" frame="border"
      border="0" rules="none">
      <tr>
        <td align="center"><a href="{$pic/@id}.html">{
          local:make-thumbnail($pic)}</a></td>
      </tr>
      { if ($pic/caption) then
      <tr>
        <td  bgcolor="#FFFF99" align="center"><a class="textual"
          href="{$pic/@id}.html">{$pic/caption/node()}</a></td>
      </tr>
      else ()}
    </table>
  </td>
  }</tr></table>
};

(: Process a sequence of <picture> elements, grouping them into
 : rows of at most 3, for the thumbnail page.
 : $prev:  An integer giving the number of <picture>s in
 :   this current sequence that precede those in $pictures.
 : $pictures:  Remaining <picture> elements to process.
 : Returns formatted HTML for the input $pictures.
 :)
declare function local:make-rows($prev, $pictures) {
  let $count := count($pictures) return
  if ($count = 0) then ()
  else if ($count <= 3) then
    local:format-row($pictures)
  else if ($count = 4 and $prev = 0) then
    (: A special case:  If there are 4 pictures in a row,
     : then group them as 2 rows of 2 rather than 3 + 1. :)
    (local:format-row(sublist($pictures, 1, 2)),
     local:format-row(sublist($pictures, 3, 2)))
  else
     (local:format-row(sublist($pictures, 1, 3)),
      local:make-rows($prev+3,sublist($pictures, 4)))
};

(: Process the children of a <group>, grouping thumbnails into rows.
 : $pictures:  Sequence of <picture>s that need to be split into rows.
 : $unseen: sequence of remaining children we have not processed yet.
 :)
declare function local:find-rows($pictures, $unseen) {
  if (empty($unseen)) then local:make-rows(0, $pictures)
  else
    let $next := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($next)
      case element(row,*) return
        (local:make-rows(0, $pictures),local:format-row($next/*),local:find-rows((), $rest))
      case element(date,*) return (: ignore <date> children here. :)
        (local:make-rows(0, $pictures),local:find-rows((), $rest))
      case element(title,*) return (: ignore <title> children here. :)
        (local:make-rows(0, $pictures),local:find-rows((), $rest))
      case element(text,*) return (: format <text> as a paragraph. :)
        (local:make-rows(0, $pictures),<p>{$next/node()}</p>,local:find-rows((), $rest))
      default return
        local:find-rows(($pictures,$next), $rest)
};

declare function local:picture-text($picture) {
  for $text in $picture/text return <p>{$text/node()}</p>
};

declare function local:make-title($picture, $group) {
  concat(string($group/title), " - ",
         if (empty($picture/caption)) then string($picture/@id)
         else string($picture/caption))
};

declare function local:make-header($picture, $group) {
  <h2>{if ($picture/caption) then $picture/caption/node()
       else $group/title/node()}</h2>
};

(: Create a 1-row navigation-bar: next, prev etc :)

declare function local:nav-bar($picture, $name, $prev, $next, $style) {
<table>
  <tr>
    <td><a class="button" id="up-button" href="index.html" onclick="top.location='index.html'">Index</a></td>
    <td width="100" align="right">{
      if ($prev) then local:make-link($prev/@id, $style, " < Previous ")
      else ()}</td>
    <td width="100" align="left">{
      if ($next) then local:make-link($next/@id, $style, " Next > ")
      else ()
    }</td>{
    if ($style="info") then () else ("
    ",<td style-button="info">{local:make-link($name, "info", "Info")}</td>),
    if ($style="large" or $style="full") then () else ("
    ",<td width="200" align="left" style-button="large">{
      local:make-link($name, "large", "Large image")}</td>),
    if ($style="") then () else ("
    ",<td width="200" align="left" style-button="medium">{
      local:make-link($name, "", "Medium image")}</td>)}
  <script language="JavaScript">WriteStyleMenu();</script>
  </tr>
</table>
};

declare function local:get-image-info ($name)
{
(:
<pre>{
  let $info := exif-loader:getImageInfo(java.io.File:new(concat($name,".jpg")))
  for $i in iterator-items(ImageInfo:getTagIterator($info)) return
 ( "
", ImageInfo:getTagName($i),": ", ImageInfo:getDescription($info, $i))
}</pre>
:)
  doc(concat($name,"-info.txt"))
};

declare function local:raw-jpg-link($image, $description) {
  if (empty($image)) then () else
  <td><span class="button"><a href="{$image}">{$description} ({
    string($image/@width)}x{string($image/@height)})</a></span></td>
};

(: Generate a page picture image with links etc.
 : $picture:  The <picture> node to use.
 : $group:  The enclosing <group>.
 : $name:  The string-value of the picture's id attribute.
 : $preamble: Paragraphs that lead-in to this (group of) pictures.
 : $prev:  The previous <picture> or the empty sequence if there is none.
 : $next:  The next <picture> or the empty sequence if there is none.
 : $date:  The date the picture was taken, as a string, or the empty sequence.
 : $style:  The style and size.
 :   Currently only "full", "large" or "" (medium) or "info".
 :   The "info" style show a thumbnail, plus EXIF information, plus links to
 :   the raw JPGs.  The "full" style is like "large" but auto-resizing.
 :)
declare function local:picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count) {
(: FIXME add documentheader and DO NOT EDIT comment :)
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <link rel="up" href="index.html" />{
    (: Note how we pre-pend whitespace to properly indent the <link>s. :)
    if (empty($prev)) then ()
    else ("
    ",<link rel="prev" href="{$prev/@id}{local:style-link($style)}.html" />),
    if (empty($next)) then ()
    else ("
    ",<link rel="next" href="{$next/@id}{local:style-link($style)}.html" />)}
    <title>{local:make-title($picture,$group)}</title>
    <style type="text/css">
      a {{ padding: 1 4; text-decoration: none; }}
      td {{ padding-left: 0; border-style: none }}
      a.button {{ border: thin solid; background-color: #FFFF99; }}
      a.button:hover {{ background-color: orange; }}
      span.button {{ border: thin solid; background-color: #FFFF99; }}
      img {{ border: thin solid black }}
      div#preamble {{ z-index: 1; top: 0px; left: 0px; width: 600px }}
      div.preamble-text {{ background-color: #FFFF99; border: 1px solid black; padding: 0.5em}}
   </style>
{(  (: (Note what we have to do to add an XQuery comment here!)
     : Next we generate a JavaScript handler, to handle pressing the keys
     : 'n' (or space) and 'p' for navigation.  The indentation of the code
     : isn't "logical", but it makes the JavaScript code look nice. :) )}
    <script language="JavaScript">
      var thisId = "{$name}";
      var nextId = "{ if (empty($next)) then "" else string($next/@id) }";
      var prevId = "{ if (empty($prev)) then "" else string($prev/@id) }";
      var libdir = "{$libdir}";
      var hash = location.hash;
      var style_link = "{local:style-link($style)}";
      var uphash = {if ($style="info") then '"#info"'
                    else if ($style="full") then 'location.hash ? location.hash : "#large"'
                    else 'location.hash?location.hash:top.slider?"#slider":""'};
    </script>
    <script language="JavaScript" type="text/javascript" src="{$libdir}/picture.js">{((:Following space needed to force output of closing tag:))} </script>
  </head>
{
  element body {
    attribute bgcolor {"#00DDDD"},
    attribute onload {"javascript:OnLoad();"},
    attribute onresize {"javascript:ScaledResize();"},
    local:above-picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count),
  let $full-image := $picture/full-image,
      $image := $picture/image
  return
  if ($style = "info") then (
    <table><tr>
      <td style="padding: 20 20 20 10">{local:make-thumbnail($picture)} </td>
      <td>{local:get-image-info($name)}</td>
    </tr></table>,"
", (: FIXME use $nl :)
    <table><tr><td>Plain JPEG images:</td>
    {local:raw-jpg-link($picture/full-image, "Original")}
    {local:raw-jpg-link($picture/image,
    if ($full-image) then "Scaled" else "Original")}
    {local:raw-jpg-link($picture/small-image, "Thumbnail")}
    </tr></table>,"
", (: FIXME use $nl :)
    let $outtakes := $picture/outtake return
      if (empty($outtakes)) then () else
        <table><tr><td>Outtakes:</td>
          {for $outtake in $outtakes return
             let $outtext := $outtake/node() return
            <td><span class="button"><a href="{string($outtake/@img)}">{if (empty($outtext)) then "picture" else $outtext}</a></span></td>}
        </tr></table>
  )
  else if (($style="large" or $style="full") and $full-image) then
    local:make-main-img($full-image, 1)
  else if ($style="full" and $image) then
    local:make-main-img($image, 1)
  else if ($style="large" and $image
           and number($image/@width) <= 640
           and number($image/@height) <= 640) then
    local:make-main-img($image, 2)
  else if ($image) then
    local:make-main-img($image, 1)
  else
    local:make-main-img($full-image, 0.5)
 }
 }
</html>,$nl
};

declare function local:above-picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count) {
<div id="preamble"><form>
{ (:if ($style="full") then () else:)
  local:nav-bar($picture, $name, $prev, $next, $style)}
<div class="preamble-text">
<p>{if ($i=$count) then "Last" else concat("Number ", $i)} of {$count}.  {
  if (empty($date)) then () else concat("Date taken: ",string($date),"."),
  if ($style="full") then <script language="JavaScript">if (scaled) document.write(" <i>[Type <code>h</code> to hide.]</i>")</script> else () }</p>
{ $preamble }
{ local:make-header($picture, $group)}
{ local:picture-text($picture)}
</div></form>
</div>
};

declare function local:make-slider-page($group) {
let $first := string($group/picture[1]/@id) return
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: 0 }}
      table.row {{ padding: 10px }}
    </style>
    <script type="text/javascript">
      function loadFrames() {{
        var hash=top.location.hash;
        var main=top.main;
        var id = hash ? hash.substring(1) : "{$first}";
        top.slider.sliderSelectId(id);
        top.slider.focus();
      }}
    </script>
  </head>
  <frameset cols="280,*" onload="top.loadFrames()">
    <frame name="slider" src="sindex.html" />
    <frame name="main" src="{$first}.html" />
  </frameset>
</html>
};

declare function local:make-slider-index-page($group) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: 0 }}
      table.row {{ padding: 10px }}
    </style>
    <script language="JavaScript" type="text/javascript" src="{$libdir}/group.js"> </script>
  <script language="JavaScript">document.onkeypress = sliderHandler;</script>
  </head>
  <body bgcolor="#00AAAA" onload="javascript:fixLinks();">
  <table cellpadding="0" frame="border"
      border="0" rules="none" >{
  for $pic in $group/* return
  typeswitch ($pic)
  case element(text,*) return <tr><td><p>{$pic/node()}</p></td></tr>
  case element(picture,*) return ("
    ",
<tr><td><table id="{$pic/@id}" bgcolor="black" onclick="javascript:onClickSlider(this)">
      <tr>
        <td align="center"><a href="{$pic/@id}.html" target="main">{
          local:make-thumbnail($pic)}</a></td>
      </tr> {
      if ($pic/caption) then
      <tr>
        <td  bgcolor="#FFFF99" align="center"><a class="textual" target="main"
          href="{$pic/@id}.html" target="main">{$pic/caption/node()}</a></td>
      </tr>
      else ()}
    </table></td></tr>)
  default return ()
}
  </table>
  </body>
</html>
};

declare function local:make-group-page($group) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="help" href="{$libdir}/help.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: 0 }}
      table.row {{ padding: 10px }}
      div#header {{ padding: 1px }}
      span.button {{ border: thin solid; background-color: #FFFF99; }}
      p#group-buttons {{ display: block; margin: 0; text-align: center;
        position: absolute;  top: 0.5em;  left: 0.5em;  width: 6em;
        right: auto;  background: #FFFF99; }}
      p#group-buttons a {{ text-decoration: none; display: block; border: thin solid black }}
      p#group-buttons a:link {{ text-decoration: none}}
      p#group-buttons a:hover {{ background: orange }}
      div#header h2 {{ position: relative;  left: 7em;  top: 0em;}}
    </style>
    <script language="JavaScript" type="text/javascript" src="{$libdir}/group.js"> </script>
  </head>
  <body bgcolor="#00AAAA" onload="javascript:fixLinks();">
  <div id="header">
  <p id="group-buttons">
    <a href="{$libdir}/help.html">Help</a>
    <a href="../index.html">Up</a>
    <a href="slider.html">Slider</a>
    </p>
    <h2>{$group/title/node()}</h2>
  </div>
{   local:find-rows((), $group/*)}
  </body>
</html>
};

(: For a given $style, recurse over pictures to link.
 : $group: the <group> document element.
 : $pictures: all the <picture> elements that a descendents of $group.
 : $i: the index in $pictures of the next <picture> to process.
 : $count: the number of <picture> elements in $pictures.
 : $style: the current style
 : $texts: <text> nodes seen so far that are not in a <picture>.
 : $unseen: the modes (<picture>, <row>, <text>) to process for this call.
 :)
declare function local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts, $unseen) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := sublist($unseen, 2)
    return
      typeswitch ($cur)
      case element(row,*) return (
	 local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts, $cur/*),
         local:loop-pictures($group, $date, $pictures, $i+count($cur//picture),
           $count, $style, (), $rest))
      case element(text,*) return
        local:loop-pictures($group, $date, $pictures, $i, $count, $style,
                      ($texts,<p>{$cur/node()}</p>), $rest)
      case element(date,*) return
        local:loop-pictures($group, $cur, $pictures, $i, $count, $style,
                      $texts, $rest)
      case element(picture,*) return
        let $prev := if ($i > 1) then item-at($pictures, $i - 1) else (),
            $next := if ($i < $count) then item-at($pictures, $i + 1) else (),
            $pdate := if ($cur/date) then $cur/date else $date,
	    $name := string($cur/@id)
        return
        (write-to(local:picture($cur,  $group, $name,
		    $texts, $prev, $next, $pdate, $style, $i, $count),
                  concat($name, local:style-link($style), ".html")),
         local:loop-pictures($group, $date, $pictures, $i+1, $count, $style, (),  $rest))
      default return
         local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts,  $rest)
};

let $group := doc("index.xml")/group,
    $group-name := $group/title,
    $pictures := $group//picture,
    $count := count($pictures)
  return (
    write-to(local:make-slider-page($group), "slider.html"),
    write-to(local:make-slider-index-page($group), "sindex.html"),
    write-to(local:make-group-page($group), "index.html"),
    for $style in ("", "info", "full")
    return
    local:loop-pictures($group, $group/date[1], $pictures, 1, $count, $style, (), $group/*))
