import{_ as s,c as a,o as n,a as l}from"./app.c3b3f769.js";const F=JSON.parse('{"title":"Pattern Matching","description":"","frontmatter":{},"headers":[{"level":2,"title":"Pattern matching examples","slug":"pattern-matching-examples","link":"#pattern-matching-examples","children":[]}],"relativePath":"intro/adts/pattern-matching.md","lastUpdated":1671084442000}'),p={name:"intro/adts/pattern-matching.md"},o=l(`<h1 id="pattern-matching" tabindex="-1">Pattern Matching <a class="header-anchor" href="#pattern-matching" aria-hidden="true">#</a></h1><p>Pattern matching with MLStyle is about deconstructing a value in the same way as how you construct it. This is true for <code>Expronicon</code>&#39;s algebra data types defined using <code>@adt</code> macro.</p><h2 id="pattern-matching-examples" tabindex="-1">Pattern matching examples <a class="header-anchor" href="#pattern-matching-examples" aria-hidden="true">#</a></h2><p>Let&#39;s first define a simple ADT describes a message (taken from rust book)</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#82AAFF;">@adt</span><span style="color:#A6ACCD;"> Message </span><span style="color:#89DDFF;">begin</span></span>
<span class="line"><span style="color:#A6ACCD;">    Quit</span></span>
<span class="line"></span>
<span class="line"><span style="color:#A6ACCD;">    </span><span style="color:#F78C6C;">struct</span><span style="color:#A6ACCD;"> Move</span></span>
<span class="line"><span style="color:#A6ACCD;">        x</span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">Int</span></span>
<span class="line"><span style="color:#A6ACCD;">        y</span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">Int</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">=</span><span style="color:#A6ACCD;"> </span><span style="color:#F78C6C;">1</span></span>
<span class="line"><span style="color:#A6ACCD;">    </span><span style="color:#89DDFF;">end</span></span>
<span class="line"></span>
<span class="line"><span style="color:#A6ACCD;">    </span><span style="color:#82AAFF;">Write</span><span style="color:#A6ACCD;">(</span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">String</span><span style="color:#A6ACCD;">)</span></span>
<span class="line"></span>
<span class="line"><span style="color:#A6ACCD;">    </span><span style="color:#82AAFF;">ChangeColor</span><span style="color:#A6ACCD;">(</span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">Int</span><span style="color:#A6ACCD;">, </span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">Int</span><span style="color:#A6ACCD;">, </span><span style="color:#89DDFF;">::</span><span style="color:#FFCB6B;">Int</span><span style="color:#A6ACCD;">)</span></span>
<span class="line"><span style="color:#89DDFF;">end</span></span>
<span class="line"></span></code></pre></div><p>the named fields can be matched using positional pattern matching:</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">@match</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">Move</span><span style="color:#A6ACCD;">(</span><span style="color:#F78C6C;">1</span><span style="color:#A6ACCD;">, </span><span style="color:#F78C6C;">2</span><span style="color:#A6ACCD;">) </span><span style="color:#89DDFF;">begin</span></span>
<span class="line"><span style="color:#A6ACCD;">           </span><span style="color:#82AAFF;">Move</span><span style="color:#A6ACCD;">(x, y) </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> x </span><span style="color:#89DDFF;">+</span><span style="color:#A6ACCD;"> y</span></span>
<span class="line"><span style="color:#A6ACCD;">           _ </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">false</span></span>
<span class="line"><span style="color:#A6ACCD;">       </span><span style="color:#89DDFF;">end</span></span>
<span class="line"><span style="color:#F78C6C;">3</span></span>
<span class="line"></span></code></pre></div><p>or using named pattern matching:</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">@match</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">Move</span><span style="color:#A6ACCD;">(</span><span style="color:#F78C6C;">1</span><span style="color:#A6ACCD;">, </span><span style="color:#F78C6C;">2</span><span style="color:#A6ACCD;">) </span><span style="color:#89DDFF;">begin</span></span>
<span class="line"><span style="color:#A6ACCD;">           </span><span style="color:#82AAFF;">Move</span><span style="color:#A6ACCD;">(;x) </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> x</span></span>
<span class="line"><span style="color:#A6ACCD;">           _ </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">false</span></span>
<span class="line"><span style="color:#A6ACCD;">       </span><span style="color:#89DDFF;">end</span></span>
<span class="line"><span style="color:#F78C6C;">1</span></span>
<span class="line"></span></code></pre></div><p>the annoymous fields can only be matched using positional pattern matching:</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">@match</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">Write</span><span style="color:#A6ACCD;">(</span><span style="color:#89DDFF;">&quot;</span><span style="color:#C3E88D;">hello</span><span style="color:#89DDFF;">&quot;</span><span style="color:#A6ACCD;">) </span><span style="color:#89DDFF;">begin</span></span>
<span class="line"><span style="color:#A6ACCD;">           </span><span style="color:#82AAFF;">Write</span><span style="color:#A6ACCD;">(s) </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> s</span></span>
<span class="line"><span style="color:#A6ACCD;">           _ </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">false</span></span>
<span class="line"><span style="color:#A6ACCD;">       </span><span style="color:#89DDFF;">end</span></span>
<span class="line"><span style="color:#89DDFF;">&quot;</span><span style="color:#C3E88D;">hello</span><span style="color:#89DDFF;">&quot;</span></span>
<span class="line"></span></code></pre></div><p>the singleton variants can be matched directly by the variant name:</p><div class="language-julia"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki"><code><span class="line"><span style="color:#A6ACCD;">julia</span><span style="color:#89DDFF;">&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#82AAFF;">@match</span><span style="color:#A6ACCD;"> Quit </span><span style="color:#89DDFF;">begin</span></span>
<span class="line"><span style="color:#A6ACCD;">        Quit </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">true</span></span>
<span class="line"><span style="color:#A6ACCD;">        _ </span><span style="color:#89DDFF;">=&gt;</span><span style="color:#A6ACCD;"> </span><span style="color:#89DDFF;">false</span></span>
<span class="line"><span style="color:#A6ACCD;">    </span><span style="color:#89DDFF;">end</span></span>
<span class="line"><span style="color:#89DDFF;">true</span></span>
<span class="line"></span></code></pre></div>`,13),e=[o];function t(c,r,C,i,y,A){return n(),a("div",null,e)}const d=s(p,[["render",t]]);export{F as __pageData,d as default};