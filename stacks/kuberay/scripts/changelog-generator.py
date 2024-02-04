from github import Github
import re


class ChangelogGenerator:
    def __init__(self, github_repo):
        # Replace <your_github_token> with your Github Token
        self._github = Github('<your_github_token>')
        self._github_repo = self._github.get_repo(github_repo)

    def generate(self, pr_id):
        pr = self._github_repo.get_pull(pr_id)

        return "{title} ([#{pr_id}]({pr_link}), @{user})".format(
            title=pr.title,
            pr_id=pr_id,
            pr_link=pr.html_url,
            user=pr.user.login
        )


# generated by `git log <oldTag>..<newTag> --oneline`
payload = '''
7374e2c [RayService] Skip update events without change (#811) (#825)
7f83353 Switch to 0.4.0 and eliminate Chart app versions. (#810)
86b0af2 Remove ingress.enabled from KubeRay operator chart (#812) (#816)
c1cbaed Update chart versions for 0.4.0-rc.0 (#804)
84a70f1 Update image tags. (#784)
d760b9c [helm] Add memory limits and resource documentation. (#789) (#798)
16905df [Feature] Improve the observability of integration tests (#775) (#796)
83aab82 [CI] Pin go version in CRD consistency check (#794) (#797)
....
'''

g = ChangelogGenerator("ray-project/kuberay")
for pr_match in re.finditer(r"#(\d+)", payload):
    pr_id = int(pr_match.group(1))
    print("* {}".format(g.generate(pr_id)))

