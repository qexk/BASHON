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
    "title":"ma bite",
    "desc":"sa vie, son histoire, ses amours, ses déboires"
}
EOF
)"

BASHON_json=$(printf %s "${BASHON_json}" | tr '\n' ' ')
# BASHON_root=$(mktemp -d)
# pushd "${BASHON_root}"

BASHON_props() {
	local lexeme="$(BASHON_consume "${BASHON_json}")"
	local pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		STRG)
			local data="${pl:1:-1}"
			echo "${data}"
		;;
		SPAC)
			BASHON_props
	esac
}

BASHON_start() {
	lexeme="$(BASHON_consume "${BASHON_json}")"
	pl="${lexeme:4}"
	BASHON_json="${BASHON_json:${#pl}}"
	case ${lexeme:0:4} in
		LACC)
			BASHON_props
		;;
		SPAC)
			
	esac
}

BASHON_start
