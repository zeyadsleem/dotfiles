#!/bin/bash

if [ -f phpcs.xml ]; then
	read -p "File phpcs.xml already exists. Do you want to overwrite it? (y/n): " confirm
	if [ "$confirm" != "y" ]; then
		echo "Operation cancelled"
		exit 1
	fi
fi

cat >phpcs.xml <<'EOF'
<?xml version="1.0"?>
<ruleset name="Custom Standard">
    <file>src</file>
    <file>tests</file>

    <exclude-pattern>vendor/*</exclude-pattern>
    <exclude-pattern>storage/*</exclude-pattern>

    <rule ref="PSR2"/>

    <rule ref="PSR1.Classes.ClassDeclaration.MissingNamespace">
        <severity>0</severity>
    </rule>

    <rule ref="Generic.Files.LineLength">
        <properties>
            <property name="lineLimit" value="120"/>
        </properties>
    </rule>
</ruleset>
EOF

if [ -f phpcs.xml ]; then
	echo "PHPCS configuration file created successfully"
	echo "Location: $(pwd)/phpcs.xml"
else
	echo "Error creating PHPCS configuration file"
	exit 1
fi
