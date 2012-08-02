import re

# replace repo-sha with a link to barkeep
def replace_shas_with_links(word):
  return re.sub(r"([a-zA-Z0-9_-]+)-([a-zA-Z0-9]{40})",
                r"<a href='http://barkeep/commits/\1/\2' target='blank'>\1-\2</a>",
                word)

# list generated from https://jira.corp.ooyala.com/secure/BrowseProjects.jspa#all
PROJECTS = set(['ANA', 'APP', 'AUTO', 'BL', 'BRB', 'CCC', 'CINE', 'CST', 'DOC', 'DS', 'FAC', 'HELP', 'INTL',
'JIRA', 'MERC', 'MIRA', 'OCS', 'OJRA', 'OPSINF', 'OPSPLAT', 'OTA', 'OTS', 'PAC', 'PL', 'PRN', 'PROD', 'PS',
'PSE', 'PWS', 'RM', 'RQ', 'SCRM', 'SFDC', 'TOOL', 'USA', 'WEB', 'XD'])

# replace PROJECT-number with a link to jira
def replace_jira_links(word):
  def check_valid_jira(match):
    if match.group(1) in PROJECTS:
      return "<a href='https://jira.corp.ooyala.com/browse/{0}-{1}' target='_blank'>{0}-{1}</a>".format(
          match.group(1), match.group(2))
    return match.group(0)

  return re.sub(r"([A-Z]+)-(\d+)",
                check_valid_jira,
                word)
