import os
import sys

# We can parse the pbxproj file manually or use a regex to add files to the group.
# Actually, since it's hard to safely modify pbxproj manually without a library,
# let's install a ruby script that uses xcodeproj.
