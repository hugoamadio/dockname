# dockname naming rules (copy to rules.sed, which git ignores, and restart dockname).
# Each line is a `sed -E` command run on the container name; the first line printed
# becomes the host. The domain (.localhost) is appended when missing.
# Containers no rule prints for keep the default names.

# api-feat42 -> feat42.api.localhost
s/^api-([a-z0-9]+)$/\1.api/p

# legacy-blog-1 -> blog.localhost
s/^legacy-([a-z]+)-[0-9]+$/\1/p
