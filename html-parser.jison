/* description: HTML parser. */

/* lexical grammar */
%lex
%%

\s+                                 /* skip whitespace */
\<                                  return 'O_ANG_BRACKET'
\>                                  return 'C_ANG_BRACKET'
\/                                  return 'SLASH'
\=                                  return '='
\"[A-z0-9:;\{\}\s]+\"               return 'VALUE'
\'[A-z0-9:;\{\}\s]+\'               return 'VALUE'
[A-z0-9]+                           return 'TEXT'
<<EOF>>                             return 'EOF'

/lex

%{

const slice = function(array, from) {
    return array.slice(from, array.length - 1);
}

const anlyseSemantics = function(tree){
    const {startTag, text, attrs, endTag, children} = tree;
    if(startTag === undefined){
       return;
    }
    if(slice(startTag, 1) !== slice(endTag, 2)){
        throw Error(`${slice(startTag, 1)} does not have closing tag`);
    }
    for(child of children){
        anlyseSemantics(child);
    }
}

const elmConverter = function(element) {
  const { startTag, text, attrs, endTag, children } = element;
  const tag = startTag.slice(1, startTag.length - 1);
  const elementAttrs = [];
  Object.entries(attrs).forEach(([key,value]) => elementAttrs.push(`${key} ${value}`));
  const childElements = children.map(elmConverter);
  return `${tag}  [${elementAttrs}] [ text \"${text}\"] [${childElements}]`;
};

%}

%start expressions

%% /* language grammar */

expressions
    : ROOT EOF
        {   anlyseSemantics($1);
            const elmTree = elmConverter($1);
            console.log(elmTree);
            typeof console !== 'undefined' ? console.log(JSON.stringify($1)) : print($1);
          return $1; }
    ;

ROOT
    : START_TAG END_TAG
        { $$ = { startTag: $1.tag, text: "", attrs: $1.attrs, endTag: $2, children: []} }
    | START_TAG TEXT END_TAG
        { $$ = { startTag: $1.tag, text: $2, attrs: $1.attrs, endTag: $3, children: []} }
    | START_TAG ELEMENTS END_TAG
        { $$ = { startTag: $1.tag, text: "", attrs: $1.attrs, endTag: $3, children: $2} }
    ;

ELEMENTS
    : ELEMENT
        { $$ = [$1] }
    | ELEMENTS ELEMENT
        { $$ = ($1).concat([$2]) }
    ;

ELEMENT
    : VOID_ELEMENT
        { $$ = $1 }
    | NON_VOID_ELEMENT
        { $$ = $1 }
    ;

VOID_ELEMENT
    : O_ANG_BRACKET TEXT SLASH C_ANG_BRACKET
        { $$ = { tag: [$1,$2,$3,$4].join(''), attrs: {}} }
    | O_ANG_BRACKET TEXT ATTRS SLASH C_ANG_BRACKET
        { $$ = { tag: [$1,$2,$4,$5].join(''), attrs: $3} }
    ;

NON_VOID_ELEMENT
    : START_TAG END_TAG
        { $$ = { startTag: $1.tag, text: "", attrs: $1.attrs, endTag: $2, children: []} }
    | START_TAG TEXT END_TAG
        { $$ = { startTag: $1.tag, text: $2, attrs: $1.attrs, endTag: $3, children: []} }
    | START_TAG ELEMENTS END_TAG
        { $$ = { startTag: $1.tag, text: "", attrs: $1.attrs, endTag: $3, children: $2} }
    ;

START_TAG
    : O_ANG_BRACKET TEXT C_ANG_BRACKET
        { $$ = { tag: [$1,$2,$3].join(''), attrs: {}} }
    | O_ANG_BRACKET TEXT ATTRS C_ANG_BRACKET
        { $$ = { tag: [$1,$2,$4].join(''), attrs: $3} }
    ;

END_TAG
    : O_ANG_BRACKET SLASH TEXT C_ANG_BRACKET
        { $$ = [$1,$2,$3,$4].join('') }
    ;

ATTRS
    : ATTR
        { $$ = $1 }
    | ATTRS ATTR
        { Object.entries($2).forEach(([key,value]) => $1[key] = value);
          $$ =  $1}
    ;

ATTR
    : TEXT '=' VALUE
        { $$ = {[$1]: $3} }
    ;