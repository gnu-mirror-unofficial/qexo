<?xml version="1.0"?>
<!-- Copyright 2000 Per Bothner <per@bothner.com> -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="picture">
<picture>
<xsl:attribute name="key"><xsl:value-of select="@id"/></xsl:attribute>
<xsl:attribute name="img"><xsl:value-of select="full-image|image"/></xsl:attribute>
<xsl:choose>
<xsl:when test="original[@rotated]">
<xsl:attribute name="rotated"><xsl:value-of select="original/@rotated"/></xsl:attribute>
</xsl:when>
<xsl:otherwise>
</xsl:otherwise>
</xsl:choose>
</picture>
<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="title">
</xsl:template>

<xsl:template match="group|row">
<xsl:apply-templates select="row|picture"/>
</xsl:template>

</xsl:stylesheet>
