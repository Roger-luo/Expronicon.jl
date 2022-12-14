import { defineConfig } from 'vitepress'

export default defineConfig({
    lang: 'en-US',
    title: 'Expronicon',
    description: 'Collective tools for metaprogramming in Julia.',
    lastUpdated: true,
    cleanUrls: 'with-subfolders',
    base: 'Expronicon.jl',

    themeConfig: {
        // siteTitle: 'My Custom Title'
        nav: nav(),
        sidebar: {
            '/intro/': sidebarIntro(),
        },
        footer: {
            message: 'Released under the MIT License.',
            copyright: 'Copyright © 2019-present Roger Luo',
        },
        algolia: {
            appId: 'SMP1LNISJ0',
            apiKey: '9c5bb6496ab253709084153de62c6bdf',
            indexName: 'expronicon'
        },
    }
})

function nav() {
    return [
        { text: 'Introduction', link: '/intro/what-is-metaprogramming' },
        { text: 'API', link: '/api' },
    ]
}

function sidebarIntro() {
    return [
        {
            text: 'Introduction',
            items: [
                // This shows `/guide/index.md` page.
                { text: 'What is Meta-Programming', link: '/intro/what-is-metaprogramming' },
                { text: 'Syntax Types', link: '/intro/syntax-types' },
                { text: 'Development Tools', link: '/intro/dev-tools' },
                { text: 'Pretty Printing', link: '/intro/pretty-print' },
                { text: 'Compile out compile-time dependencies', link: '/intro/bootstrap' },
            ]
        },
        {
            text: 'Code Analysis',
            items: [
                { text: 'Split Functions', link: '/intro/analysis/split' },
                { text: 'Checks', link: '/intro/analysis/check' },
                { text: 'Heuristic', link: '/intro/analysis/heuristic' },
                { text: 'Miscellaneous', link: '/intro/analysis/misc' },
            ]
        },
        {
            text: 'Code Transformation',
            items: [
                { text: 'Code Transformation', link: '/intro/code-transform/transforms' },
            ]
        },
        {
            text: 'Code Generators',
            items: [
                { text: 'The x functions', link: '/intro/code-generators/the-x-function' },
            ]
        },
        {
            text: 'Algebra Data Types',
            items: [
                { text: 'Introduction', link: '/intro/adts/intro' },
                { text: 'Defining ADTs', link: '/intro/adts/defining' },
                { text: 'Pattern Matching', link: '/intro/adts/pattern-matching' },
                { text: 'A Simple Language', link: '/intro/adts/simple-lang' },
            ]
        }
    ]
}
