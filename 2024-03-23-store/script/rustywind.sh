#/bin/bash

set -e

rustywind "$@" --custom-regex "\bclass[\s(<|]+\"([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclass[\s(]+\"[^\"]*\"[\s+]+\"([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclass[\s<|]+\"[^\"]*\"\s*\+{2}\s*\" ([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclass[\s<|]+\"[^\"]*\"\s*\+{2}\s*\" [^\"]*\"\s*\+{2}\s*\" ([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclass[\s<|]+\"[^\"]*\"\s*\+{2}\s*\" [^\"]*\"\s*\+{2}\s*\" [^\"]*\"\s*\+{2}\s*\" ([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclassList[\s\[\(]+\"([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclassList[\s\[\(]+\"[^\"]*\",\s[^\)]+\)[\s\[\(,]+\"([^\"]*)\"" .
rustywind "$@" --custom-regex "\bclassList[\s\[\(]+\"[^\"]*\",\s[^\)]+\)[\s\[\(,]+\"[^\"]*\",\s[^\)]+\)[\s\[\(,]+\"([^\"]*)\"" .
