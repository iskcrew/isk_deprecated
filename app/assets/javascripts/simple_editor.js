var SVG;
var SVG_HEAD;
var SVG_TEXT;
var INPUT_TEXT;
var INPUT_TEXT_SIZE;
var INPUT_TEXT_ALIGN;
var INPUT_HEAD;
var INPUT_COLOR;
var CODE;
var SERIALIZE;
var TEMPLATE_TEXT_X;
var TEMPLATE_WIDTH;

var svgNS = "http://www.w3.org/2000/svg";
var xmlNS = "http://www.w3.org/XML/1998/namespace";

function prepare(){
  INPUT_TEXT_ALIGN=document.getElementById("text_align");
  INPUT_TEXT_ALIGN.addEventListener('change', update, false);

  INPUT_TEXT_SIZE=document.getElementById("text_size");
  INPUT_TEXT_SIZE.addEventListener('change', update, false);

  INPUT_COLOR=document.getElementById("color");
  INPUT_COLOR.addEventListener('change', update, false);

  INPUT_TEXT=document.getElementById("text");
  INPUT_TEXT.addEventListener('input', update, false);
  INPUT_TEXT.wrap='off';

  INPUT_HEAD=document.getElementById("head");
  INPUT_HEAD.addEventListener('input', update, false);
  INPUT_HEAD.wrap='off';

  CODE=document.getElementById("code");

  SERIALIZE = new XMLSerializer();

  var S=document.getElementById("svg");
  try{SVG=S.contentDocument}
  catch(err){SVG=S.getSVGDocument}

  SVG_TEXT=SVG.getElementById('slide_content');
  SVG_HEAD=SVG.getElementById('header');

  TEMPLATE_TEXT_X=parseInt(SVG_TEXT.getAttributeNS(null, 'x'));
  TEMPLATE_WIDTH=parseInt(SVG.getElementsByTagName('svg')[0].getAttributeNS(null, 'width'));
}

function clear_element(element) {
  while (element.firstChild) {
    element.removeChild(element.firstChild);
  }
}

function create_text_tspan(text, fcolor) {
  var tspan = document.createElementNS(svgNS, "tspan");
  tspan.appendChild(SVG.createTextNode(text));
  if (fcolor) tspan.setAttributeNS(null, "fill", fcolor);
  return tspan;
}

function create_line_tspan(text, fcolor) {
  var array=text.split(/<([^>]*)>/g);
  var tspan = document.createElementNS(svgNS, "tspan");
  tspan.setAttributeNS(xmlNS, "xml:space", "preserve");
  for (var i in array) {
    if (i%2) {
      if (array[i]) tspan.appendChild(create_text_tspan(array[i], fcolor));
    } else {
      if (array[i]) tspan.appendChild(create_text_tspan(array[i]));
    }
  }
  tspan.appendChild(SVG.createTextNode(" "));
  return tspan;
}


function set_multiline_align(output, input, align) {
  if (align == "Left") {
    output.setAttributeNS(null, "x", (TEMPLATE_TEXT_X));
    output.setAttributeNS(null, "text-anchor", "start");
    input.style.textAlign = "left";
  } else if (align == "Right") {
    output.setAttributeNS(null, "x", (TEMPLATE_WIDTH - TEMPLATE_TEXT_X));
    output.setAttributeNS(null, "text-anchor", "end");
    input.style.textAlign = "right";
  } else if (align == "Centered") {
    output.setAttributeNS(null, "x", (TEMPLATE_WIDTH / 2));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  } else if (align == "Left Centered") {
    var center_width=parseInt(output.getBBox().width);
    output.setAttributeNS(null, "x", (TEMPLATE_TEXT_X + (center_width / 2)));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  } else if (align == "Right Centered") {
    var center_width=parseInt(output.getBBox().width);
    output.setAttributeNS(null, "x", ((TEMPLATE_WIDTH - TEMPLATE_TEXT_X) - (center_width / 2)));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  }
}

function set_multiline_text(output, input, size, fcolor) {
  var linearray=input.value.split(/\r\n|\n|\r/);
  clear_element(output);
  if (size) output.setAttributeNS(null, "font-size", size);
  var x=output.getAttributeNS(null, "x")
  for (var i in linearray) {
    var tspan = create_line_tspan(linearray[i], fcolor);
    if (i > 0) tspan.setAttributeNS(null, "dy", "1em");
    tspan.setAttributeNS(null, "x", x);
    output.appendChild(tspan);
  }
}

function update(){
  set_multiline_text(SVG_HEAD, INPUT_HEAD);
  var align=INPUT_TEXT_ALIGN.value;
  var size=INPUT_TEXT_SIZE.value;
  var color=INPUT_COLOR.value;
  set_multiline_text(SVG_TEXT, INPUT_TEXT, size, color);
  set_multiline_align(SVG_TEXT, INPUT_TEXT, align);
  set_multiline_text(SVG_TEXT, INPUT_TEXT, size, color);

  CODE.value=SERIALIZE.serializeToString(SVG);
}

function onload() {
  prepare();
  update();
};

window.addEventListener ?  window.addEventListener("load",onload,false) : 
window.attachEvent && window.attachEvent("onload",onload);
