import { defineConfig } from 'vitepress'

export default defineConfig({
    lang: 'en-US',
    title: 'Expronicon',
    description: 'Collective tools for metaprogramming in Julia.',
    lastUpdated: true,
    cleanUrls: 'with-subfolders',

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
        editLink: {
            pattern: 'https://github.com/Roger-luo/Expronicon.jl/edit/main/docs/page/:path',
            text: 'Edit this page on GitHub'
        },
        socialLinks: [
            { icon: 'github', link: 'https://github.com/Roger-luo/Expronicon.jl' }
        ]
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
            ]
        }
    ]
}
