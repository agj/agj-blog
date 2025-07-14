# Updates robots.txt and .htaccess with fresh data from the ai.robots.txt
# project, to block AI crawlers.

let aiRobotsTxtBaseUrl = "https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main"

def splitLines [] {
  split row "\n"
}

let localHtaccessLines = open ./public/.htaccess | splitLines
let localRobotstxtLines = open ./public/robots.txt | splitLines
let aiRobotsTxtHtaccessLines = http get $"($aiRobotsTxtBaseUrl)/.htaccess" | splitLines
let aiRobotsTxtRobotstxtLines = http get $"($aiRobotsTxtBaseUrl)/robots.txt" | splitLines

def insertLines [linesToInsert, sourceLines] {
  let startLine = "# Start ai.robots.txt"
  let endLine = "# End ai.robots.txt"

  let firstSplit = $sourceLines | split list $startLine
  let before = $firstSplit | get 0
  let secondSplit = $firstSplit | get 1 | split list $endLine
  let after = $secondSplit | get 1

  $before ++ [$startLine] ++ $linesToInsert ++ [$endLine] ++ $after
}

let modifiedLocalHtaccess = insertLines $aiRobotsTxtHtaccessLines $localHtaccessLines | str join "\n"
let modifiedLocalRobotstxt = insertLines $aiRobotsTxtRobotstxtLines $localRobotstxtLines | str join "\n"

$modifiedLocalHtaccess | save --force ./public/.htaccess
$modifiedLocalRobotstxt | save --force ./public/robots.txt
