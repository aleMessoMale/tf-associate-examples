terraform {
  required_providers {
    github = {
      source = "integrations/github"
      #version = "4.17.0"
    }
  }
}

provider "github" {
  token = var.github_token
}

resource "github_repository" "new_repo" {
  name        = "repository-created-from-tf"
  description = "My awesome codebase automatically created"

  visibility = "public"

}