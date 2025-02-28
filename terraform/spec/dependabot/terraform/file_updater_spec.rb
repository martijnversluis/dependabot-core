# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/dependency_file"
require "dependabot/terraform/file_updater"
require_common_spec "file_updaters/shared_examples_for_file_updaters"

RSpec.describe Dependabot::Terraform::FileUpdater do
  it_behaves_like "a dependency file updater"

  subject(:updater) do
    described_class.new(dependency_files: files, dependencies: dependencies, credentials: credentials)
  end

  let(:files) { [] }
  let(:dependencies) { [] }
  let(:credentials) do
    [{ "type" => "git_source", "host" => "github.com", "username" => "x-access-token", "password" => "token" }]
  end

  describe "#updated_dependency_files" do
    subject { updater.updated_dependency_files }

    context "with a valid dependency file" do
      let(:files) { project_dependency_files("git_tags") }
      let(:dependencies) do
        [
          Dependabot::Dependency.new(
            name: "origin_label",
            version: "0.4.1",
            previous_version: "0.3.7",
            requirements: [{
              requirement: nil,
              groups: [],
              file: "main.tf",
              source: {
                type: "git",
                url: "https://github.com/cloudposse/terraform-null-label.git",
                branch: nil,
                ref: "tags/0.4.1"
              }
            }],
            previous_requirements: [{
              requirement: nil,
              groups: [],
              file: "main.tf",
              source: {
                type: "git",
                url: "https://github.com/cloudposse/terraform-null-label.git",
                branch: nil,
                ref: "tags/0.3.7"
              }
            }],
            package_manager: "terraform"
          )
        ]
      end

      specify { expect(subject).to all(be_a(Dependabot::DependencyFile)) }
      specify { expect(subject.length).to eq(1) }
    end

    describe "the updated file" do
      let(:dependencies) do
        [
          Dependabot::Dependency.new(
            name: "origin_label",
            version: "0.4.1",
            previous_version: "0.3.7",
            requirements: [{
              requirement: nil,
              groups: [],
              file: "main.tf",
              source: {
                type: "git",
                url: "https://github.com/cloudposse/terraform-null-label.git",
                branch: nil,
                ref: "tags/0.4.1"
              }
            }],
            previous_requirements: [{
              requirement: nil,
              groups: [],
              file: "main.tf",
              source: {
                type: "git",
                url: "https://github.com/cloudposse/terraform-null-label.git",
                branch: nil,
                ref: "tags/0.3.7"
              }
            }],
            package_manager: "terraform"
          )
        ]
      end

      context "with a git dependency" do
        let(:files) { project_dependency_files("git_tags") }

        it "updates the requirement" do
          updated_file = subject.find { |file| file.name == "main.tf" }

          expect(updated_file.content).to include(
            "module \"origin_label\" {\n"\
            "  source     = \"git::https://github.com/cloudposse/"\
            "terraform-null-label.git?ref=tags/0.4.1\"\n"
          )
        end

        it "doesn't update the duplicate" do
          updated_file = subject.find { |file| file.name == "main.tf" }

          expect(updated_file.content).to include(
            "module \"duplicate_label\" {\n"\
            "  source     = \"git::https://github.com/cloudposse/"\
            "terraform-null-label.git?ref=tags/0.3.7\"\n"
          )
        end
      end

      context "with a registry dependency" do
        let(:files) { project_dependency_files("registry") }
        let(:dependencies) do
          [
            Dependabot::Dependency.new(
              name: "hashicorp/consul/aws",
              version: "0.3.1",
              previous_version: "0.1.0",
              requirements: [{
                requirement: "0.3.1",
                groups: [],
                file: "main.tf",
                source: {
                  type: "registry",
                  registry_hostname: "registry.terraform.io",
                  module_identifier: "hashicorp/consul/aws"
                }
              }],
              previous_requirements: [{
                requirement: "0.1.0",
                groups: [],
                file: "main.tf",
                source: {
                  type: "registry",
                  registry_hostname: "registry.terraform.io",
                  module_identifier: "hashicorp/consul/aws"
                }
              }],
              package_manager: "terraform"
            )
          ]
        end

        it "updates the requirement" do
          updated_file = subject.find { |file| file.name == "main.tf" }

          expect(updated_file.content).to include(
            "module \"consul\" {\n"\
            "  source = \"hashicorp/consul/aws\"\n"\
            "  version = \"0.3.1\"\n"\
            "}"
          )
        end
      end

      context "with a terragrunt file" do
        let(:files) { project_dependency_files("terragrunt") }

        let(:dependencies) do
          [
            Dependabot::Dependency.new(
              name: "gruntwork-io/modules-example",
              version: "0.0.5",
              previous_version: "0.0.2",
              requirements: [{
                requirement: nil,
                groups: [],
                file: "main.tfvars",
                source: {
                  type: "git",
                  url: "git@github.com:gruntwork-io/modules-example.git",
                  branch: nil,
                  ref: "v0.0.5"
                }
              }],
              previous_requirements: [{
                requirement: nil,
                groups: [],
                file: "main.tfvars",
                source: {
                  type: "git",
                  url: "git@github.com:gruntwork-io/modules-example.git",
                  branch: nil,
                  ref: "v0.0.2"
                }
              }],
              package_manager: "terraform"
            )
          ]
        end

        it "updates the requirement" do
          updated_file = subject.find { |file| file.name == "main.tfvars" }

          expect(updated_file.content).to include(
            "source = \"git::git@github.com:gruntwork-io/modules-example.git//"\
            "consul?ref=v0.0.5\""
          )
        end
      end
    end
  end
end
