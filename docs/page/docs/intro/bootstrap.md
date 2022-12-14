# Compile out compile-time dependencies

`Expronicon` provides a set of tools to compile out compile-time dependencies. This is useful
for those who want to have low startup times. `Expronicon` itself actually uses this feature
to compile out the `MLStyle` dependency because all pattern matching macros genreates
Julia expression only depends on Julia `Base`.

The [`bootstrap` script in the `bin` folder](https://github.com/Roger-luo/Expronicon.jl/blob/main/bin/bootstrap) is the best example of how to use this feature.
