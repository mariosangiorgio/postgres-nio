import NIOCore

extension PostgresMessage {
    /// First message sent from the frontend during startup.
    public struct Error: PostgresMessageType, CustomStringConvertible {
        public static var identifier: PostgresMessage.Identifier {
            return .error
        }
        
        /// Parses an instance of this message type from a byte buffer.
        public static func parse(from buffer: inout ByteBuffer) throws -> Error {
            var fields: [Field: String] = [:]
            while let field = buffer.readInteger(as: Field.self) {
                guard let string = buffer.readNullTerminatedString() else {
                    throw PostgresError.protocol("Could not read error response string.")
                }
                fields[field] = string
            }
            return .init(fields: fields)
        }
        
        public enum Field: UInt8, Hashable {
            /// Severity: the field contents are ERROR, FATAL, or PANIC (in an error message),
            /// or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message), or a
            //// localized translation of one of these. Always present.
            case localizedSeverity = 0x53 /// S
            
            /// Severity: the field contents are ERROR, FATAL, or PANIC (in an error message),
            /// or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message).
            /// This is identical to the S field except that the contents are never localized.
            /// This is present only in messages generated by PostgreSQL versions 9.6 and later.
            case severity = 0x56 /// V
            
            /// Code: the SQLSTATE code for the error (see Appendix A). Not localizable. Always present.
            case sqlState = 0x43 /// C
            
            /// Message: the primary human-readable error message. This should be accurate but terse (typically one line).
            /// Always present.
            case message = 0x4D /// M
            
            /// Detail: an optional secondary error message carrying more detail about the problem.
            /// Might run to multiple lines.
            case detail = 0x44 /// D
            
            /// Hint: an optional suggestion what to do about the problem.
            /// This is intended to differ from Detail in that it offers advice (potentially inappropriate)
            /// rather than hard facts. Might run to multiple lines.
            case hint = 0x48 /// H
            
            /// Position: the field value is a decimal ASCII integer, indicating an error cursor
            /// position as an index into the original query string. The first character has index 1,
            /// and positions are measured in characters not bytes.
            case position = 0x50 /// P
            
            /// Internal position: this is defined the same as the P field, but it is used when the
            /// cursor position refers to an internally generated command rather than the one submitted by the client.
            /// The q field will always appear when this field appears.
            case internalPosition = 0x70 /// p
            
            /// Internal query: the text of a failed internally-generated command.
            /// This could be, for example, a SQL query issued by a PL/pgSQL function.
            case internalQuery = 0x71 /// q
            
            /// Where: an indication of the context in which the error occurred.
            /// Presently this includes a call stack traceback of active procedural language functions and
            /// internally-generated queries. The trace is one entry per line, most recent first.
            case locationContext = 0x57 /// W
            
            /// Schema name: if the error was associated with a specific database object, the name of
            /// the schema containing that object, if any.
            case schemaName = 0x73 /// s
            
            /// Table name: if the error was associated with a specific table, the name of the table.
            /// (Refer to the schema name field for the name of the table's schema.)
            case tableName = 0x74 /// t
            
            /// Column name: if the error was associated with a specific table column, the name of the column.
            /// (Refer to the schema and table name fields to identify the table.)
            case columnName = 0x63 /// c
            
            /// Data type name: if the error was associated with a specific data type, the name of the data type.
            /// (Refer to the schema name field for the name of the data type's schema.)
            case dataTypeName = 0x64 /// d
            
            /// Constraint name: if the error was associated with a specific constraint, the name of the constraint.
            /// Refer to fields listed above for the associated table or domain. (For this purpose, indexes are
            /// treated as constraints, even if they weren't created with constraint syntax.)
            case constraintName = 0x6E /// n
            
            /// File: the file name of the source-code location where the error was reported.
            case file = 0x46 /// F
            
            /// Line: the line number of the source-code location where the error was reported.
            case line = 0x4C /// L
            
            /// Routine: the name of the source-code routine reporting the error.
            case routine = 0x52 /// R
        }
        
        /// The diagnostic messages.
        public var fields: [Field: String]
        
        /// See `CustomStringConvertible`.
        public var description: String {
            let unique = self.fields[.routine] ?? self.fields[.sqlState] ?? "unknown"
            let message = self.fields[.message] ?? "Unknown"
            return "\(message) (\(unique))"
        }
    }
}
