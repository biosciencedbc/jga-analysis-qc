# frozen_string_literal: true

require 'fileutils'

require_relative '../chr_region'
require_relative 'vcf'

module JgaAnalysisQC
  module Report
    class Sample
      class VcfCollection
        # @return [Array<Vcf>]
        attr_reader :vcfs

        # @param vcfs [Array<Vcf>]
        def initialize(vcfs)
          @vcfs = vcfs
        end

        # @return [Table, nil]
        def bcftools_stats_table
          header = ['chr. region', '# of SNPs', '# of indels', 'ts/tv']
          type = %i[string integer integer float]
          rows = @vcfs.filter_map(&:bcftools_stats).map do |e|
            [e.chr_region.desc, e.num_snps, e.num_indels, e.ts_tv_ratio]
          end
          Table.new(header, rows, type)
        end

        # @return [Table]
        def vcf_path_table
          path_table('input file', &:vcf_path)
        end

        # @return [Table]
        def bcftools_stats_path_table
          path_table('metrics file') do |vcf|
            vcf.bcftools_stats&.path
          end
        end

        private

        # @param caption [String]
        # @return        [Table, nil]
        def path_table(caption)
          return nil if @vcfs.empty?

          header = ['chr. region', caption]
          type = %i[string verbatim]
          rows =
            @vcfs.filter_map do |vcf|
              path = yield vcf
              next unless path

              [vcf.chr_region.desc, File.expand_path(path)]
            end
          Table.new(header, rows, type)
        end
      end
    end
  end
end
