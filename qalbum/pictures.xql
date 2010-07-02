declare namespace PictureInfo = "class:qalbum.PictureInfo";
declare namespace SelectFiles = "class:qalbum.SelectFiles";
declare namespace Path = "class:gnu.text.Path";
declare boundary-space preserve;
declare variable $libdir external;
declare variable $nl := "&#10;";
declare variable $pwd := Path:currentPath();
declare variable $bgcolor := "#40E0E0";

declare function local:dont-skip($picinfo) {
  PictureInfo:dontSkip($picinfo)
 (: let $rating := PictureInfo:getRating($picinfo)
  return $rating eq 0 or $rating gt 2:)
};

declare function local:make-img($class, $picinfo) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <img class="{$class}" src="{$image-name}"
    width="{PictureInfo:getScaledWidth($picinfo, $class)}"
    height="{PictureInfo:getScaledHeight($picinfo, $class)}"/>
};

declare function local:make-main-img($picinfo, $scale as xs:double, $class) {
  let $image-name := PictureInfo:getScaledFile($picinfo, $class) return
  <img class="main" id="main-image" src="{$image-name}"
    width="{PictureInfo:getWidthFor($picinfo, $image-name) * $scale}"
    height="{PictureInfo:getHeightFor($picinfo, $image-name) * $scale}"/>
};

declare function local:make-thumbnail($picinfo) {
  local:make-img("thumb", $picinfo)
};

declare function local:style-link($style) {
  if ($style="full") then "large" else $style
};

declare function local:make-style-link($picture-name, $style, $text) {
  <span class="button" style-button="{if ($style="") then "medium" else $style}"><a href="{$picture-name}{local:style-link($style)}.html">{$text}</a></span>
};

declare function local:get-caption($picinfo) {
  PictureInfo:getCaption($picinfo)
};

declare function local:format-group-image($pinfo) {
  let $label := PictureInfo:getLabel($pinfo) return
  <span class="piclink">
   <table cellpadding="0" frame="border" border="0" rules="none">
      <tr>
        <td align="center"><a fixup="style" href="{$label}.html">{
          local:make-thumbnail($pinfo)}</a></td>
      </tr>
      <tr>{
      let $caption := local:get-caption($pinfo) return
      if ($caption) then <td align="center" class="caption">{$caption}</td>
      else
 <td style="visibility: hidden" class="caption">(No caption)</td> (: For better alignment :)
      }</tr>
    </table>
  </span>
};

declare function local:picture-text($picture) {
  for $text in $picture/text return <tr>{$text/node()}</tr>
};

declare function local:make-title($picinfo, $group) {
  let $caption := local:get-caption($picinfo) return
  concat(string($group/title), " - ",
         if ($caption) then string($caption) else  PictureInfo:getLabel($picinfo))
};

(: Create a 1-row navigation-bar: next, prev etc :)

declare function local:nav-bar($name, $prevId, $nextId, $style) {
<span>
  <span class="button"><a class="button" id="up-button" href="index.html">Index</a></span>
  {if ($prevId) then
  <span class="button"><a id="prev-button" href="{$prevId}{local:style-link($style)}.html"> &lt; Previous </a></span>
  else <span class="button" style="visibility: hidden"> &lt; Previous </span>}{
  if ($nextId) then
  <span class="button"><a id="next-button" href="{$nextId}{local:style-link($style)}.html"> Next &gt; </a></span>
  else <span class="button" style="visibility: hidden"> Next &gt; </span>
  }
  {
  if ($style="info") then () else ("
  ",local:make-style-link($name, "info", "Info")),
  if ($style="large" or $style="full") then () else ("
  ",local:make-style-link($name, "large", "Large image")),
  if ($style="") then () else ("
  ",local:make-style-link($name, "", "Medium image"))}
  <script language="JavaScript">document.write(StyleMenu());</script>
</span>
};

declare function local:raw-jpg-link($class, $description, $picinfo) {
  if (PictureInfo:getScaledExists($picinfo, $class)) then
   let $image := PictureInfo:getScaledFile($picinfo, $class) return
  <td><span class="button"><a href="{$image}">{$description} {PictureInfo:getSizeDescription($picinfo, $image)}</a></span></td>
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
declare function local:picture($picinfo, $group, $name, $preamble, $text, $prevId, $nextId, $date, $style, $i, $count, $outtakes) {
(: FIXME add documentheader and DO NOT EDIT comment :)
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
    <link rel="up" href="index.html" />{
    (: Note how we pre-pend whitespace to properly indent the <link>s. :)
    if ($prevId)
    then ("
    ",<link rel="prev" href="{$prevId}{local:style-link($style)}.html" />)
    else (),
    if ($nextId)
    then ("
    ",<link rel="next" href="{$nextId}{local:style-link($style)}.html" />)
    else ()}
    <title>{local:make-title($picinfo,$group)}</title>
    <style type="text/css">
      a {{ padding: 1 4; text-decoration: none; }}
      td {{ padding-left: 0; border-style: none }}
      a.button {{ border: thin solid; background-color: #FFFF99; }}
      a.button:hover {{ background-color: orange; }}
      span.button {{ border: thin solid; background-color: #FFFF99; margin-right: 1em }}
      img {{ border: thin solid black }}
      div#preamble {{ z-index: 1; top: 0px; left: 0px;}}
      div.preamble-text {{ background-color: #FFFF99; border: 1px solid black; padding: 0.5em; width: 70%}}
   </style>
   <meta name="viewport" content="target-densitydpi=device-dpi" /><!--For Android-->{(
    (: (Note what we have to do to add an XQuery comment here!)
     : Next we generate a JavaScript handler, to handle pressing the keys
     : 'n' (or space) and 'p' for navigation.  The indentation of the code
     : isn't "logical", but it makes the JavaScript code look nice. :) )}
    <script language="JavaScript">
      var thisId = "{$name}";
      var nextId = "{$nextId}";
      var prevId = "{$prevId}";
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
    attribute bgcolor {$bgcolor},
    attribute onload {"javascript:OnLoad();"},
    attribute onresize {"javascript:ScaledResize();"},
    local:above-picture($picinfo, $group, $name, $text, $preamble, $prevId, $nextId, $date, $style, $i, $count),
  if ($style = "info") then (
    <table><tr>
      <td style="padding: 20 20 20 10">{local:make-thumbnail($picinfo)} </td>
      <td><pre>
{PictureInfo:getImageDescription($picinfo)}
</pre></td>
    </tr></table>,"
", (: FIXME use $nl :)
    <table><tr><td>Plain JPEG images:</td>
    {local:raw-jpg-link("original", "Original", $picinfo)}
    {if (PictureInfo:getScaledExists($picinfo, "medium")
         and PictureInfo:getScaledExists($picinfo, "original")) then
     let $mimage := PictureInfo:getScaledFile($picinfo, "medium"),
         $oimage := PictureInfo:getScaledFile($picinfo, "original"),
         $mfile := string($mimage),
         $ofile := string($oimage)
     where $mfile ne $ofile
     return
    <td><span class="button"><a href="{$mfile}">Scaled {PictureInfo:getSizeDescription($picinfo, $mimage)}</a></span></td>
    else ()}
    {local:raw-jpg-link("thumb", "Thumbnail", $picinfo)}
    </tr></table>,"
", (: FIXME use $nl :)
      if (empty($outtakes)) then () else
        <table><tr><td>Outtakes:</td>
          {for $outtake in $outtakes return
             let $outtext := $outtake/node() return
            <td><span class="button"><a href="{string($outtake/@img)}">{if (empty($outtext)) then "picture" else $outtext}</a></span></td>}
        </tr></table>
  )
  else if (($style="large" or $style="full")
           and PictureInfo:getScaledExists($picinfo, "large")) then
    local:make-main-img($picinfo, 1e0, "l")
  else if (not(PictureInfo:getScaledExists($picinfo, "medium"))) then
    local:make-main-img($picinfo, 0.5e0, "l")
  else if ($style="full") then
    local:make-main-img($picinfo, 1e0, "m")
  else if ($style="large"
           and (let $image-name := PictureInfo:getScaledFile($picinfo, "medium")
                return
                 PictureInfo:getWidthFor($picinfo, $image-name) <= 640 and
                 PictureInfo:getHeightFor($picinfo, $image-name) <= 640)) then
      local:make-main-img($picinfo, 2e0, "m")
  else
      local:make-main-img($picinfo, 1e0, "m")
 }
 }
</html>,$nl
};

declare function local:above-picture($picinfo, $group, $name, $text, $preamble, $prevId, $nextId, $date, $style, $i, $count) {
<div id="preamble"><form>
{ (:if ($style="full") then () else:)
  local:nav-bar($name, $prevId, $nextId, $style)}
<div class="preamble-text">
{ $preamble }
<table width="100%"><tr>
<td><font size="4"><b>{let $caption := local:get-caption($picinfo) return
  if ($caption) then $caption else $group/title/node()}</b></font>
</td>
<td align="right">{if ($i=$count) then "Last" else concat("Number&#xA0;", $i)}&#xA0;of&#xA0;{$count}.  
{if (empty($date)) then () else concat("Date&#xA0;taken:&#xA0;",string($date),".")}
</td></tr></table>
{ if ($style="full") then <script language="JavaScript">if (scaled) document.write(" <i>[Type <code>h</code> to hide.]</i>")</script> else () }
{ $text }
</div></form>
</div>
};

declare function local:make-slider-page($group, $picinfos) {
let $first := PictureInfo:getLabel(item-at($picinfos,1)) return
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="top" href="../../index.html" />
    <script type="text/javascript">
      var sliderBgcolor = "{$bgcolor}";
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
      img {{ border: thin solid black }}
      td.caption {{ background-color: #FFFF99 }}
    </style>
    <script language="JavaScript" type="text/javascript" src="{$libdir}/group.js"> </script>
  <script language="JavaScript">document.onkeypress = sliderHandler;</script>
  </head>
  <body bgcolor="{$bgcolor}" onload="javascript:fixLinks();">
  <table cellpadding="0" frame="border"
      border="0" rules="none" >{
  let $nodes := $group/* return
    local:slider-index-page-helper($nodes, 1, count($nodes), $picinfos, 1)
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
      case element(select) return
        if ($p gt count($picinfos) or fn:not($item is PictureInfo:getKey(item-at($picinfos, $p))))
      then
          local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p)
      else
          (local:format-slider-image(item-at($picinfos, $p)),
          local:slider-index-page-helper($nodes, $i, $n, $picinfos, $p+1))
      case element(picture) return
        if ($p <= count($picinfos) and $item is PictureInfo:getKey(item-at($picinfos, $p)))
      then (
        local:format-slider-image(item-at($picinfos, $p)),
        local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p+1))
      else
        local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p)
  default return
    local:slider-index-page-helper($nodes, $i+1, $n, $picinfos, $p)
};

declare function local:format-slider-image($picinfo) {
  let $caption := local:get-caption($picinfo),
      $label := PictureInfo:getLabel($picinfo)
  return ("
    ",
      <tr><td><table id="{$label}" onclick="sliderSelectCurStyle('{$label}'); return false">
      <tr>
        <td align="left"><a fixup="style" href="slider.html#{$label}" target="main">{
          local:make-thumbnail($picinfo)}</a></td>
      </tr> {
      if ($caption) then
      <tr>
        <td align="center" class="caption">{$caption}</td>
      </tr>
      else ()}
    </table></td></tr>)
};

declare function local:group-page-helper($nodes, $i, $n,
                                                $picinfos, $p) {
  if ($i > $n) then ()
  else
  let $item := item-at($nodes, $i) return
    typeswitch ($item)
      case element(text) return
        (<tr><td><p>{$item/node()}</p></td></tr>,
          local:group-page-helper($nodes, $i+1, $n, $picinfos, $p))
      case element(row) return (: deprecated :)
        let $pictures := $item/picture
        let $npictures := count($pictures) return
          (local:group-page-helper($pictures, 1, $npictures,
                                          $picinfos, $p),
           local:group-page-helper($nodes, $i+1, $n,
                                          $picinfos, $p+$npictures))
      case element(select) return
        if ($p <= count($picinfos) and $item is PictureInfo:getKey(item-at($picinfos, $p)))
        then (
          local:format-group-image(item-at($picinfos, $p)),
          local:group-page-helper($nodes, $i, $n, $picinfos, $p+1))
        else
          local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
      case element(picture) return
      if ($p > count($picinfos) or fn:not($item is PictureInfo:getKey(item-at($picinfos, $p))))
      then
        local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
      else (
      local:format-group-image(item-at($picinfos, $p)),
      local:group-page-helper($nodes, $i+1, $n, $picinfos, $p+1))
  default return
    local:group-page-helper($nodes, $i+1, $n, $picinfos, $p)
};

declare function local:make-group-page($group, $picinfos) {
<html>
  <head>
    {$group/title}
    <link rel="up" href="../index.html" />
    <link rel="help" href="{$libdir}/help.html" />
    <link rel="top" href="../../index.html" />
    <style type="text/css">
      a.textual {{ text-decoration: none }}
      img {{ border: thin solid black }}
      td.caption {{ background-color: #FFFF99 }}
      div#header {{ padding: 1px; width: 720 }}
      span.button {{ border: thin solid; background-color: #FFFF99; }}
      p#group-buttons {{ display: block; margin: 0; text-align: center;
        position: absolute;  top: 0.5em;  left: 0.5em;  width: 6em;
        right: auto;  background: #FFFF99; }}
      p#group-buttons a {{ text-decoration: none; display: block; border: thin solid black }}
      p#group-buttons a:link {{ text-decoration: none}}
      p#group-buttons a:hover {{ background: orange }}
      div#header h2 {{ position: relative;  left: 7em;  top: 0em;}}
      table {{ display: inline}}
    </style>
    <script language="JavaScript" type="text/javascript" src="{$libdir}/group.js"> </script>
  </head>
  <body bgcolor="{$bgcolor}" onload="javascript:fixLinks();">
  <div id="header">
  <p id="group-buttons">
    <a href="{$libdir}/help.html">Help</a>
    <a href="../index.html">Up</a>
    <a href="slider.html">Slider</a>
    </p>
    <h2>{$group/title/node()}</h2>
  </div>
{ let $nodes := $group/* return
    local:group-page-helper($nodes, 1, count($nodes), $picinfos, 1)
}
  </body>
</html>
};

(: For a given $style, recurse over pictures to link.
 : $group: the <group> document element.
 : $i: the index in $picinfos of the next picture to process.
 : $count: the count of $picinfos
 : $style: the current style
 : $texts: <text> nodes seen so far that are not in a <picture>.
 : $unseen: the nodes (<picture>, <row>, <text>) to process for this call.
 :)
declare function local:loop-pictures($group, $date, $i, $count, $style, $texts, $unseen, $picinfos) {
  if (empty($unseen)) then ()
  else
    let $cur := item-at($unseen, 1),
        $rest := subsequence($unseen, 2)
    return
      typeswitch ($cur)
      case element(row) return (
	 local:loop-pictures($group, $date, $i, $count, $style, $texts, $cur/*, $picinfos),
         local:loop-pictures($group, $date, $i+count($cur//picture),
           $count, $style, (), $rest, $picinfos))
      case element(text) return
        local:loop-pictures($group, $date, $i, $count, $style,
                      ($texts,<p>{$cur/node()}</p>), $rest, $picinfos)
      case element(date) return
        local:loop-pictures($group, $cur, $i, $count, $style,
                      $texts, $rest, $picinfos)
      case element(select) return
      if ($i > $count or fn:not($cur is PictureInfo:getKey(item-at($picinfos, $i))))
      then
        local:loop-pictures($group, $date, $i, $count, $style,
                      (), $rest, $picinfos)
      else
        let $picinfo := item-at($picinfos, $i),
            $prevId := if ($i > 1) then PictureInfo:getLabel(item-at($picinfos, $i - 1)) else "",
            $nextId := if ($i < $count) then PictureInfo:getLabel(item-at($picinfos, $i + 1)) else "",
	    $name := PictureInfo:getLabel($picinfo)
        return (
        write-to-if-changed(local:picture($picinfo, $group, $name,
		    $texts, local:picture-text($cur),
                    $prevId, $nextId, $date, $style, $i, $count, ()),
                  resolve-uri(concat($name, local:style-link($style), ".html"), $pwd)),
        local:loop-pictures($group, $date, $i+1, $count, $style,
                      (), $unseen, $picinfos))
      case element(picture) return
        if ($i > $count or fn:not($cur is PictureInfo:getKey(item-at($picinfos, $i))))
      then
        local:loop-pictures($group, $date, $i, $count, $style, (), $rest, $picinfos)
      else
        let $prevId := if ($i > 1) then PictureInfo:getLabel(item-at($picinfos, $i - 1)) else "",
            $nextId := if ($i < $count) then PictureInfo:getLabel(item-at($picinfos, $i + 1)) else "",
            $pdate := if ($cur/date) then $cur/date else $date,
            $picinfo := item-at($picinfos, $i),
	    $name := PictureInfo:getLabel($picinfo)
        return (
        write-to-if-changed(local:picture($picinfo, $group, $name,
		    $texts, local:picture-text($cur),
                    $prevId, $nextId, $pdate, $style, $i, $count,
                    $cur/outtake),
                  resolve-uri(concat($name, local:style-link($style), ".html"), $pwd)),
         local:loop-pictures($group, $date, $i+1, $count, $style, (),  $rest, $picinfos))
      default return
         local:loop-pictures($group, $date, $i, $count, $style, $texts, $rest, $picinfos)
};

declare function local:get-pictures($nodes) {
  for $cur in $nodes return
  typeswitch ($cur)
      case element(row) return local:get-pictures($cur/*)
      case element(picture) return
        let $full-image := $cur/full-image,
            $image := if ($full-image) then $full-image else $cur/image,
            $pinfo := PictureInfo:getImages($cur, string($cur/@id),
                                     string($cur/original/@rotated),
                                     string($image), string($cur/caption))
        where local:dont-skip($pinfo)
        return $pinfo
      case element(select) return
        SelectFiles:selectFiles(string($cur/@path), $cur)
      default return ()
};

let $index-file-uri := resolve-uri("index.xml", $pwd),
    $group := doc($index-file-uri)/group,
    $group-name := $group/title,
    $picinfos := local:get-pictures($group/*),
    $count := count($picinfos)
  return (
    write-to-if-changed(local:make-slider-page($group, $picinfos), resolve-uri("slider.html", $pwd)),
    write-to-if-changed(local:make-slider-index-page($group, $picinfos), resolve-uri("sindex.html", $pwd)),
    write-to-if-changed(local:make-group-page($group, $picinfos), resolve-uri("index.html", $pwd)),
    for $style in ("", "info", "full")
    return
    local:loop-pictures($group, $group/date[1], 1, $count, $style, (), $group/*, $picinfos)
)
