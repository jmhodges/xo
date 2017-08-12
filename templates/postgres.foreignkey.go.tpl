{{- $short := (shortname .Type.Name) -}}
// {{ .Name }} returns the {{ .RefType.Name }} associated with the {{ .Type.Name }}'s {{ .Field.Name }} ({{ .Field.Col.ColumnName }}).
//
// Generated from foreign key '{{ .ForeignKey.ForeignKeyName }}'.
func ({{ $short }} *{{ .Type.Name }}) {{ .Name }}(db XODB) (*{{ .RefType.Name }}, error) {
	return {{ $short}}.{{.Name}}Context(context.Background(), db)
}
    
// {{ .Name }}Context returns the {{ .RefType.Name }} associated with the {{ .Type.Name }}'s {{ .Field.Name }} ({{ .Field.Col.ColumnName }}).
//
// Generated from foreign key '{{ .ForeignKey.ForeignKeyName }}'.
func ({{ $short }} *{{ .Type.Name }}) {{ .Name }}Context(ctx context.Context, db XODB) (*{{ .RefType.Name }}, error) {
	return {{ .RefType.Name }}By{{ .RefField.Name }}Context(ctx, db, {{ convext $short .Field .RefField }})
}

