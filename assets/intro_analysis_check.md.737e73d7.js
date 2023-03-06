import{_ as s,c as n,o as a,a as l}from"./app.17aa78ac.js";const D=JSON.parse('{"title":"Checks","description":"","frontmatter":{},"headers":[],"relativePath":"intro/analysis/check.md","lastUpdated":1670998942000}'),p={name:"intro/analysis/check.md"},e=l(`<h1 id="checks" tabindex="-1">Checks <a class="header-anchor" href="#checks" aria-hidden="true">#</a></h1><p><code>Expronicon</code> provides a rich set of check functions. These functions are used to check the semantics of an expression. For example, <code>is_function</code> checks if an expression is a function.</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">is_function</span><span style="color:#A6ACCD;">(:(</span><span style="color:#82AAFF;">f</span><span style="color:#A6ACCD;">(x) </span><span style="color:#89DDFF;">=</span><span style="color:#A6ACCD;"> x </span><span style="color:#89DDFF;">+</span><span style="color:#A6ACCD;"> </span><span style="color:#F78C6C;">1</span><span style="color:#A6ACCD;">))</span></span>
<span class="line"><span style="color:#89DDFF;">true</span></span>
<span class="line"></span>
<span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">is_function</span><span style="color:#A6ACCD;">(:(x </span><span style="color:#89DDFF;">+</span><span style="color:#A6ACCD;"> </span><span style="color:#F78C6C;">1</span><span style="color:#A6ACCD;">))</span></span>
<span class="line"><span style="color:#89DDFF;">false</span></span>
<span class="line"></span></code></pre></div><p>Here is a list of all the check functions:</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">is_function</span></span>
<span class="line"><span style="color:#A6ACCD;">is_kw_function</span></span>
<span class="line"><span style="color:#A6ACCD;">is_struct</span></span>
<span class="line"><span style="color:#A6ACCD;">is_tuple</span></span>
<span class="line"><span style="color:#A6ACCD;">is_splat,</span></span>
<span class="line"><span style="color:#A6ACCD;">is_ifelse</span></span>
<span class="line"><span style="color:#A6ACCD;">is_for</span></span>
<span class="line"><span style="color:#A6ACCD;">is_field</span></span>
<span class="line"><span style="color:#A6ACCD;">is_field_default</span></span>
<span class="line"><span style="color:#A6ACCD;">is_datatype_expr</span></span>
<span class="line"><span style="color:#A6ACCD;">is_matrix_expr</span></span>
<span class="line"><span style="color:#A6ACCD;">has_symbol</span></span>
<span class="line"><span style="color:#A6ACCD;">is_literal</span></span>
<span class="line"><span style="color:#A6ACCD;">is_gensym</span></span>
<span class="line"><span style="color:#A6ACCD;">alias_gensym</span></span>
<span class="line"><span style="color:#A6ACCD;">has_kwfn_constructor</span></span>
<span class="line"><span style="color:#A6ACCD;">has_plain_constructor</span></span>
<span class="line"><span style="color:#A6ACCD;">compare_expr</span></span>
<span class="line"></span></code></pre></div>`,5),o=[e];function c(t,i,r,C,A,_){return a(),n("div",null,o)}const d=s(p,[["render",c]]);export{D as __pageData,d as default};
