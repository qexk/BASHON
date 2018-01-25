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
		s/^("([^"]|\\")*").*/STRG\1/;t
		s/^([[:space:]]+).*/SPAC\1/;t
		s/^.*/!!!!/;t
	')"
}

BASHON_json="$(cat << EOF
{
    "title": "ma bite",
    "desc": "sa vie, son histoire, ses amours, ses déboires",
    "meta": {
        "author": "Alexandre Szymocha",
        "year": 2018
    }
}
EOF
)"

BASHON_json=$(printf %s "${BASHON_json}" | tr '\n' ' ')

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
		SPAC)
			BASHON_kv_key
	esac
}

BASHON_start() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		LACC)
			mkdir -p "${1}" && pushd "${1}" >/dev/null
			BASHON_kv_key
		;;
		STRG)
			printf "%s" "${pl:1:-1}" > "STRG${1}"
		;;
		NMBR)
			printf "%s" "${pl}" > "NMBR${1}"
		;;
		SPAC)
			BASHON_start "${1}"
	esac
}

BASHON_root="parsed" #$(mktemp -u)
BASHON_start "${BASHON_root}"
