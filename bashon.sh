BASHON_consume() {
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

BASHON_json="$(cat test/json1.json)"
BASHON_json="$(printf %s "${BASHON_json}" | tr '\n' ' ')"

BASHON_kv_next() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		COMA)
			BASHON_kv_key
		;;
		RACC)
			popd >/dev/null
		;;
		SPAC)
			BASHON_kv_next
	esac
}

BASHON_kv_colon() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		COLN)
			BASHON_start "${1}"
			BASHON_kv_next
		;;
		SPAC)
			BASHON_kv_colon "${1}"
	esac
}

BASHON_kv_key() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		STRG)
			BASHON_kv_colon "${pl:1:-1}"
		;;
		RACC)
			popd >/dev/null
		;;
		SPAC)
			BASHON_kv_key
	esac
}

BASHON_array_cont() {
	local idx="${1:-0}"
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case "${lexeme:0:4}" in
		COMA)
			BASHON_start "${idx}"
			BASHON_array_cont "$(( ${idx} + 1  ))"
		;;
		RBRA)
			popd >/dev/null
		;;
		SPAC)
			BASHON_array_cont "${idx}"
	esac
}

BASHON_array() {
	local idx="${1:-0}"
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	case ${lexeme:0:4} in
		RBRA)
			BASHON_json="${BASHON_json:${#pl}}"
			popd >/dev/null
		;;
		SPAC)
			BASHON_json="${BASHON_json:${#pl}}"
			BASHON_array "${idx}"
		;;
		*)
			BASHON_start "${idx}"
			BASHON_array_cont "$(( ${idx} + 1 ))"
	esac
}

BASHON_prep_key() {
	printf %s "${1}" | sed 's/\\/\\\\/g;s:/:\\|:g'
}

BASHON_dir() {
	local name="${1}$(BASHON_prep_key "${2}")"
	rm -rf "????${name:4}"
	mkdir "${name}"
	echo "${name}"
}

BASHON_file() {
	local name="${1}$(BASHON_prep_key "${2}")"
	rm -rf "????${name:4}"
	touch "${name}"
	echo "${name}"
}

BASHON_start() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local tag="${lexeme:0:4}"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${tag} in
		LACC)
			pushd "$(BASHON_dir DICT "${1}")" >/dev/null
			BASHON_kv_key
		;;
		LBRA)
			pushd "$(BASHON_dir TABL "${1}")" >/dev/null
			BASHON_array
		;;
		NULL|TRUE|FALS)
			BASHON_file "${tag}" "${1}" >/dev/null
		;;
		NMBR)
			printf "%s" "${pl}" > "$(BASHON_file NMBR "${1}")"
		;;
		STRG)
			printf "%s" "${pl:1:-1}" > "$(BASHON_file STRG "${1}")"
		;;
		SPAC)
			BASHON_start "${1}"
	esac
}

BASHON_root="parsed" #$(mktemp -u)
BASHON_start "${BASHON_root}"
