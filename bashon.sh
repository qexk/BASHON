_BASHON_json=

#BEGIN Parsers
_BASHON_consume() {
	echo "$(printf %s "${1}" | sed -E '
		s/^\{.*/LACC{/;t
		s/^\}.*/RACC}/;t
		s/^\[.*/LBRA[/;t
		s/^\].*/RBRA]/;t
		s/^,.*/COMA,/;t
		s/^:.*/COLN:/;t
		s/^null.*/NULLnull/;t
		s/^true.*/TRUEtrue/;t
		s/^false.*/FALSfalse/;t
		s/^(-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?).*/NMBR\1/;t
		s/^("(\\\\|\\"|[^"])*").*/STRG\1/;t
		s/^([[:space:]]+).*/SPAC\1/;t
		s/^.*/!!!!/;t
	')"
}

_BASHON_kv_next() {
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		COMA)
			_BASHON_kv_key
		;;
		RACC)
			popd >/dev/null
		;;
		SPAC)
			_BASHON_kv_next
	esac
}

_BASHON_kv_colon() {
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		COLN)
			_BASHON_start "${1}"
			_BASHON_kv_next
		;;
		SPAC)
			_BASHON_kv_colon "${1}"
	esac
}

_BASHON_kv_key() {
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		STRG)
			_BASHON_kv_colon "${pl:1:-1}"
		;;
		RACC)
			popd >/dev/null
		;;
		SPAC)
			_BASHON_kv_key
	esac
}

_BASHON_array_cont() {
	local idx="${1:-0}"
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case "${lexeme:0:4}" in
		COMA)
			_BASHON_start "${idx}"
			_BASHON_array_cont "$(( ${idx} + 1  ))"
		;;
		RBRA)
			popd >/dev/null
		;;
		SPAC)
			_BASHON_array_cont "${idx}"
	esac
}

_BASHON_array() {
	local idx="${1:-0}"
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	case ${lexeme:0:4} in
		RBRA)
			_BASHON_json="${_BASHON_json:${#pl}}"
			popd >/dev/null
		;;
		SPAC)
			_BASHON_json="${_BASHON_json:${#pl}}"
			_BASHON_array "${idx}"
		;;
		*)
			_BASHON_start "${idx}"
			_BASHON_array_cont "$(( ${idx} + 1 ))"
	esac
}

_BASHON_prep_key() {
	printf %s "${1}" | sed 's/\\/\\\\/g;s:/:\\|:g'
}

_BASHON_dir() {
	local name="${1}$(_BASHON_prep_key "${2}")"
	rm -rf ????"${name:4}"
	mkdir "${name}"
	echo "${name}"
}

_BASHON_file() {
	local name="${1}$(_BASHON_prep_key "${2}")"
	rm -rf ????"${name:4}"
	touch "${name}"
	echo "${name}"
}

_BASHON_start() {
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local tag="${lexeme:0:4}"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case ${tag} in
		LACC)
			pushd "$(_BASHON_dir DICT "${1}")" >/dev/null
			_BASHON_kv_key
		;;
		LBRA)
			pushd "$(_BASHON_dir TABL "${1}")" >/dev/null
			_BASHON_array
		;;
		NULL|TRUE|FALS)
			_BASHON_file "${tag}" "${1}" >/dev/null
		;;
		NMBR)
			printf "%s" "${pl}" > "$(_BASHON_file NMBR "${1}")"
		;;
		STRG)
			printf "%s" "${pl:1:-1}" \
				> "$(_BASHON_file STRG "${1}")"
		;;
		SPAC)
			_BASHON_start "${1}"
	esac
}
#END Parsers

#BEGIN Generators
_BASHON_gen_start() {
	:
}
#END Generators

BASHON_parse() {
	_BASHON_json="$(printf %s "${1}" | tr '\n' ' ')"
	local root="${2:-$(mktemp -u)}"
	if [[ -z ${root//[^\/]} ]]; then
		local true_root=
		_BASHON_start "${root}"
		for file in ????"${root}"; do
			[[ $file -nt $true_root ]] && true_root="${file}"
		done
		printf %s "$(_BASHON_prep_key "${true_root}")"
	else
		local true_root=
		local root_path="${root%/*}"
		local root_node="${root##*/}"
		pushd "${root_path}" >/dev/null
		_BASHON_start "${root_node}"
		for file in ????"${root_node}"; do
			[[ $file -nt $true_root ]] && true_root="${file}"
		done
		popd >/dev/null
		printf %s "${root_path}/$(_BASHON_prep_key "${true_root}")"
	fi
}

BASHON_generate() {
	local root="${1}"
	if [[ $* < 1 || ! -e $root ]]; then
		return 1
	fi
	if [[ -z ${root//[^\/]} ]]; then
		printf %s "$(_BASHON_gen_start "${root}")"
	else
		local root_path="${root%/*}"
		local root_node="${root##*/}"
		pushd "${root_path}" >/dev/null
		printf %s "$(_BASHON_gen_start "${root_node}")"
		popd >/dev/null
	fi
}
