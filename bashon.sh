shopt -s nullglob

_BASHON_json=

#BEGIN Parsers
_BASHON_consume() {
	printf %s "$(printf %s "${1}" | sed -E '
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

_BASHON_tabl_cont() {
	local idx="${1:-0}"
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case "${lexeme:0:4}" in
		COMA)
			_BASHON_start ".${idx}"
			_BASHON_tabl_cont "$(( ${idx} + 1  ))"
		;;
		RBRA)
			popd >/dev/null
		;;
		SPAC)
			_BASHON_tabl_cont "${idx}"
	esac
}

_BASHON_tabl() {
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
			_BASHON_tabl "${idx}"
		;;
		*)
			_BASHON_start ".${idx}"
			_BASHON_tabl_cont "$(( ${idx} + 1 ))"
	esac
}

_BASHON_prep_key() {
	printf %s "${1}" | sed 's/\\/\\\\/g;s:/:\\|:g'
}

_BASHON_dir() {
	local name="${1}$(_BASHON_prep_key "${2}")"
	rm -rf ./????"${name:4}"
	mkdir "./${name}"
	printf %s "${name}"
}

_BASHON_file() {
	local name="${1}$(_BASHON_prep_key "${2}")"
	rm -rf ./????"${name:4}"
	touch "./${name}"
	printf %s "${name}"
}

_BASHON_start() {
	local lexeme="$(_BASHON_consume "${_BASHON_json}")"
	local tag="${lexeme:0:4}"
	local pl="${lexeme:4}"
	_BASHON_json="${_BASHON_json:${#pl}}"
	case ${tag} in
		LACC)
			pushd "./$(_BASHON_dir DICT "${1}")" >/dev/null
			_BASHON_kv_key
		;;
		LBRA)
			pushd "./$(_BASHON_dir TABL "${1}")" >/dev/null
			_BASHON_tabl
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
_BASHON_gen_key() {
	printf %s "${1}" | sed 's:\\|:/:g;s/\\\\/\\/g'
}

_BASHON_gen_dict() {
	[[ ! -d $1 ]] && return
	pushd "./${1}" >/dev/null
	local sep=
	for file in *; do
		printf %s "${sep}\"$(_BASHON_gen_key "${file:4}")\":"\
			"$(_BASHON_gen_start "${file}")"
		sep=,
	done
	popd >/dev/null
}

_BASHON_gen_tabl() {
	[[ ! -d $1 ]] && return
	pushd "./${1}" >/dev/null
	# I really hesitated to throw in a sleep sort or a bubble sort here
	local sep=
	local IFS=
	while read -d $'\0' file; do
		printf %s "${sep}$(_BASHON_gen_start "${file}")"
		sep=,
	done < <(printf '%s\0' * | sort -zt. -k2)
	popd >/dev/null
}

_BASHON_gen_start() {
	local tag=${1:0:4}
	case ${tag} in
		DICT)
			printf %s "{$(_BASHON_gen_dict "${1}")}"
		;;
		TABL)
			printf %s "[$(_BASHON_gen_tabl "${1}")]"
		;;
		STRG)
			printf %s "\"$(cat ${1})\""
		;;
		NMBR)
			printf %s "$(cat ${1})"
		;;
		NULL|TRUE)
			printf %s "${tag,,}"
		;;
		FALS)
			printf %s false
	esac
}
#END Generators

BASHON_parse() {
	[[ $1 == '-h' ]] && cat <<-EOH && return
Usage: BASHON_parse <path.json> [<store-path>]
EOH
	_BASHON_json="$(printf %s "${1}" | tr '\n' ' ')"
	local root="${2:-$(mktemp -u)}"
	if [[ $root =~ .*/.* ]]; then
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
	else
		local true_root=
		_BASHON_start "${root}"
		for file in ????"${root}"; do
			[[ $file -nt $true_root ]] && true_root="${file}"
		done
		printf %s "$(_BASHON_prep_key "${true_root}")"
	fi
}

BASHON_generate() {
	[[ $1 == '-h' ]] && cat <<-EOH && return
Usage: BASHON_generate <root>
EOH
	local root="${1}"
	[[ $* < 1 || ! -e $root ]] && return 1
	if [[ $root =~ .*/.* ]]; then
		local root_path="${root%/*}"
		local root_node="${root##*/}"
		pushd "${root_path}" >/dev/null
		printf %s "$(_BASHON_gen_start "${root_node}")"
		popd >/dev/null
	else
		printf %s "$(_BASHON_gen_start "${root}")"
	fi
}
