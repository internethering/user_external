app_name=user_external

project_dir=$(CURDIR)
build_dir=$(CURDIR)/build/artifacts
appstore_dir=$(build_dir)/appstore
source_dir=$(build_dir)/source
sign_dir=$(build_dir)/sign
package_name=$(app_name)
cert_dir=$(HOME)/.nextcloud/certificates
github_account=internethering
branch=master
version+=master


# Cleaning
clean:
	rm -rf $(build_dir)

# releasing to github
release: appstore github-release github-upload

github-release:
	github-release release \
		--user $(github_account) \
		--repo $(app_name) \
		--target $(branch) \
		--tag v$(version) \
		--name "$(app_name) v$(version)"

github-upload:
	github-release upload \
		--user $(github_account) \
		--repo $(app_name) \
		--tag v$(version) \
		--name "$(app_name)-$(version).tar.gz" \
		--file $(build_dir)/$(app_name)-$(version).tar.gz

# creating .tar.gz + signature
appstore:
	mkdir -p $(sign_dir)
	rsync -a \
	--exclude=/build \
	--exclude=/tests \
	--exclude=/.git \
	--exclude=/.github \
	--exclude=/.drone.yml \
	--exclude=/CONTRIBUTING.md \
	--exclude=/issue_template.md \
	--exclude=/README.md \
	--exclude=/.gitattributes \
	--exclude=/.gitignore \
	--exclude=/.scrutinizer.yml \
	--exclude=/.travis.yml \
	--exclude=/Makefile \
	$(project_dir)/ $(sign_dir)/$(app_name)
	@if [ -f $(cert_dir)/$(app_name).key ]; then \
		echo "Signing app files…"; \
		sudo -u www-data php ../../occ integrity:sign-app \
			--privateKey=$(cert_dir)/$(app_name).key\
			--certificate=$(cert_dir)/$(app_name).crt\
			--path=$(sign_dir)/$(app_name); \
	fi
	tar -czf $(build_dir)/$(app_name).tar.gz \
		-C $(sign_dir) $(app_name)
	@if [ -f $(cert_dir)/$(app_name).key ]; then \
		echo "Signing package…"; \
		openssl dgst -sha512 -sign $(cert_dir)/$(app_name).key $(build_dir)/$(app_name).tar.gz | openssl base64; \
	fi
