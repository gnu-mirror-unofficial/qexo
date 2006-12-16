declare namespace PictureInfo = "class:qalbum.PictureInfo";
declare boundary-space preserve;
declare variable $libdir external;
declare variable $nl := "&#10;";

declare function local:make-img($image, $scale as xs:double, $class, $picinfo) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <img class="{$class}" src="{$image-name}"
    width="{PictureInfo:getScaledWidth($picinfo, $class) * $scale}"
    height="{PictureInfo:getScaledHeight($picinfo, $class) * $scale}"/>
};

declare function local:make-main-img($image, $scale as xs:double, $class, $picinfo) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <img class="main" id="main-image" src="{$image-name}"
    width="{PictureInfo:getWidthFor($picinfo, $image-name) * $scale}"
    height="{PictureInfo:getHeightFor($picinfo, $image-name) * $scale}"/>
};

declare function local:make-thumbnail($pic, $picinfo) {
  local:make-img($pic/small-image, 1.0e0, "thumb", $picinfo)
};

declare function local:style-link($style) {
  if ($style="full") then "large" else $style
};

declare function local:make-link($picture-name, $style, $text) {
  <a class="button" href="{$picture-name}{local:style-link($style)}.html" onclick="OnClick('{$picture-name}')">{$text}</a>
};

declare function local:format-row($first, $last, $pictures, $picinfos) {
  "&#10;  ", (: emit a newline for readabilty :)
  <table class="row"><tr>{
  for $i in $first to $last
  let $pic := item-at($pictures, $i) return
  <td align="center">
   <table bgcolor="black" cellpadding="0" frame="border"
      border="0" rules="none">
      <tr>
        <td align="center"><a fixup="style" href="{$pic/@id}.html">{
          local:make-thumbnail($pic, item-at($picinfos, $i))}</a></td>
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
 : $count: Total number of pictures.
 : $pictures:  Remaining <picture> elements to process.
 : Returns formatted HTML for the input $pictures.
 :)
declare function local:make-rows($first, $last, $pictures, $picinfos) {
  let $count := $last - $first + 1 return
  if ($count = 0) then ()
  else if ($count=4) then (: special case to display 2+2 rather than 3+1 :)
    (local:format-row($first, $first+1, $pictures, $picinfos),
     local:format-row($first+2, $last, $pictures, $picinfos))
  else
  let $lastrow := (($count + 2) mod 3) + 1 return
    (local:make-rows($first, $last - $lastrow, $pictures, $picinfos),
     local:format-row($last - $lastrow + 1, $last, $pictures, $picinfos))
};

(: Process the children of a <group>, grouping thumbnails into rows.
 : $first: Index (in $pictures) of next picture to emit thumbnail for.
 : $ntext: Index (in $pictures) of first <picture> element in unseen.
 : $pictures:  Sequence of all the <picture> elements.
 : $picinfos:  Sequence of corresponding PictureInfo object.
 : $unseen: sequence of remaining children we have not processed yet.
 :)
declare function local:find-rows($first, $next, $unseen,
                                 $pictures, $picinfos) {
  if (empty($unseen)) then
    local:make-rows($first, $next - 1, $pictures, $picinfos)
  else
    let $item := item-at($unseen, 1),
        $rest := subsequence($unseen, 2)
    return
      if ($item instance of element(picture)) then
        (: Add the picture picture to the pending <picture> sequence :)
        local:find-rows($first, $next+1, $rest, $pictures, $picinfos)
      else
        (local:make-rows($first, $next - 1, $pictures, $picinfos),
         if ($item instance of element(row)) then
           let $rcount := count($item/picture) return
             (local:format-row($next, $next +$rcount -1, $pictures, $picinfos),
              local:find-rows($next+$rcount, $next+$rcount, $rest, $pictures, $picinfos))
         else
           ((if ($item instance of element(text)) then
             <p>{$item/node()}</p>
             else () (: ignore <date>, <title> here :)),
            local:find-rows($next, $next, $rest, $pictures, $picinfos)))
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
      if ($prev) then
      <a class="button" id="prev-button" href="{$prev/@id}{local:style-link($style)}.html"> &lt; Previous </a>
      else ()}</td>
    <td width="100" align="left">{
      if ($next) then
      <a class="button" id="next-button" href="{$next/@id}{local:style-link($style)}.html"> Next &gt; </a>
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

declare function local:raw-jpg-link($class, $description, $picinfo) {
  if (PictureInfo:getScaledExists($picinfo, $class)) then
   let $image := PictureInfo:getScaledFile($picinfo, $class) return
  <td><span class="button"><a href="{$image}">{$description} {PictureInfo:getSizeDescription($picinfo, string($image))}</a></span></td>
  else ()
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
declare function local:picture($picture, $group, $name, $preamble, $prev, $next, $date, $style, $i, $count, $picinfo) {
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
      <td style="padding: 20 20 20 10">{local:make-thumbnail($picture, $picinfo)} </td>
      <td><pre>
{PictureInfo:getImageDescription($picinfo)}
</pre></td>
    </tr></table>,"
", (: FIXME use $nl :)
    <table><tr><td>Plain JPEG images:</td>
    {local:raw-jpg-link("original", "Original", $picinfo)}
    {local:raw-jpg-link("medium",
    if ($full-image) then "Scaled" else "Original", $picinfo)}
    {local:raw-jpg-link("thumb", "Thumbnail", $picinfo)}
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
    local:make-main-img($full-image, 1e0, "l", $picinfo)
  else if ($style="full" and $image) then
    local:make-main-img($image, 1e0, "m", $picinfo)
  else if ($style="large" and $image
           and (let $image-name := string($image) return
                 PictureInfo:getWidthFor($picinfo, $image-name) <= 640 and
                 PictureInfo:getHeightFor($picinfo, $image-name) <= 640)) then
    local:make-main-img($image, 2e0, "m", $picinfo)
  else if ($image) then
    local:make-main-img($image, 1e0, "m", $picinfo)
  else
    local:make-main-img($full-image, 0.5e0, "l", $picinfo)
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

declare function local:make-slider-index-page($group, $picinfos) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      p {{ font-size: small }}
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
  let $nodes := $group/* return
    local:slider-index-page-helper($nodes, 1 , count($nodes), $picinfos, 1)
}
  </table>
  </body>
</html>
};

(: Recurse over nodes to produce a slider.
 : $nodes: the nodes to process.
 : $i: next node (as an index in $nodes) to process.
 : $n: count($nodes).
 : $picinfos: The PictureInfo objects
 : $p: next picture (as an index in $picinfos) to process.
 :)
declare function local:slider-index-page-helper($nodes, $i, $n,
                                                $picinfos, $p) {
  if ($i > $n) then ()
  else
  let $item := item-at($nodes, $i) return
    typeswitch ($item)
      case element(text) return
        (<tr><td><p>{$item/node()}</p></td></tr>,
          local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p))
      case element(row) return
        let $pictures := $item/picture
        let $npictures := count($pictures) return
          (local:slider-index-page-helper($pictures, 1, $npictures,
                                          $picinfos, $p),
           local:slider-index-page-helper($nodes, $i+1, $n,
                                          $picinfos, $p+$npictures))
      case element(picture) return ("
    ",
      <tr><td><table id="{$item/@id}" bgcolor="black" onclick="javascript:onClickSlider(this)">
      <tr>
        <td align="center"><a href="{$item/@id}.html" target="main">{
          local:make-thumbnail($item, item-at($picinfos, $p))}</a></td>
      </tr> {
      if ($item/caption) then
      <tr>
        <td  bgcolor="#FFFF99" align="center"><a class="textual"
          href="{$item/@id}.html" target="main">{$item/caption/node()}</a></td>
      </tr>
      else ()}
    </table></td></tr>,
    local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p+1))
  default return
    local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p)
};


declare function local:make-group-page($group, $pictures, $picinfos) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="help" href="{$libdir}/help.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: 0 }}
      table.row {{ padding: 10px; width: 100% }}
      div#header {{ padding: 1px; width: 720 }}
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
{   local:find-rows(1, 1, $group/*, $pictures, $picinfos)}
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
declare function local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts, $unseen, $picinfos) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := subsequence($unseen, 2)
    return
      typeswitch ($cur)
      case element(row) return (
	 local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts, $cur/*, $picinfos),
         local:loop-pictures($group, $date, $pictures, $i+count($cur//picture),
           $count, $style, (), $rest, $picinfos))
      case element(text) return
        local:loop-pictures($group, $date, $pictures, $i, $count, $style,
                      ($texts,<p>{$cur/node()}</p>), $rest, $picinfos)
      case element(date) return
        local:loop-pictures($group, $cur, $pictures, $i, $count, $style,
                      $texts, $rest, $picinfos)
      case element(picture) return
        let $prev := if ($i > 1) then item-at($pictures, $i - 1) else (),
            $next := if ($i < $count) then item-at($pictures, $i + 1) else (),
            $pdate := if ($cur/date) then $cur/date else $date,
	    $name := string($cur/@id)
        return
        (write-to-if-changed(local:picture($cur,  $group, $name,
		    $texts, $prev, $next, $pdate, $style, $i, $count, item-at($picinfos, $i)),
                  concat($name, local:style-link($style), ".html")),
         local:loop-pictures($group, $date, $pictures, $i+1, $count, $style, (),  $rest, $picinfos))
      default return
         local:loop-pictures($group, $date, $pictures, $i, $count, $style, $texts,  $rest, $picinfos)
};

let $group := doc("file:./index.xml")/group,
    $group-name := $group/title,
    $pictures := $group//picture,
    $picinfos :=
      for $p in $pictures
        return PictureInfo:getImages(string($p/@id),
                                            string($p/original/@rotated),
                                            string($p/full-image)),
    $count := count($pictures)
  return (
    write-to-if-changed(local:make-slider-page($group), "slider.html"),
    write-to-if-changed(local:make-slider-index-page($group, $picinfos), "sindex.html"),
    write-to-if-changed(local:make-group-page($group, $pictures, $picinfos), "index.html"),
    for $style in ("", "info", "full")
    return
    local:loop-pictures($group, $group/date[1], $pictures, 1, $count, $style, (), $group/*, $picinfos)
)
