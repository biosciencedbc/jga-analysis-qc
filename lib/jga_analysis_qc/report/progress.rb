# frozen_string_literal: true

require 'pathname'
require 'fileutils'

require_relative '../settings'
require_relative '../sample'
require_relative 'render'
require_relative 'paging'
require_relative 'table'

module JgaAnalysisQC
  module Report
    class Progress
     TEMPLATE_PREFIX = 'progress'

      # @return [Pathname]
      attr_reader :result_dir

      # @return [Array<Sample>]
      attr_reader :samples

      # @param result_dir           [Pathname]
      # @param samples              [Array<Sample>]
      def initialize(result_dir, samples)
        @result_dir = result_dir
        @samples = samples.sort_by(&:end_time).reverse
        max_pages = (MAX_SAMPLES.to_f / NUM_SAMPLES_PER_PAGE).ceil
        @num_digits = max_pages.digits.length
      end

      # @return [Array<Pathname>] HTML paths
      def render
        slices = @samples.each_slice(NUM_SAMPLES_PER_PAGE).to_a
        slices.map.with_index(1) do |slice, page_num|
          paging = Paging.new(page_num, slices.length, @num_digits)
          table = sample_slice_to_table(slice)
          Render.run(TEMPLATE_PREFIX, result_dir, binding, paging: paging)
        end
      end

      private

      # @param slice [Array<Sample>]
      # @return      [Table]
      def sample_slice_to_table(slice)
        header = ['name', 'end time']
        type = %i[string string]
        rows = slice.map do |sample|
          name = Render.markdown_link_text(sample.name, "#{sample.name}/report.html")
          [name, sample.end_time]
        end
        Table.new(header, rows, type)
      end

      # @param prefix [String]
      # @param paging [Paging]
      # @return       [String]
      def navigation_markdown_text(prefix, paging)
        prev_text, next_text = %w[prev next].map do |nav|
          digits = paging.send(nav)&.digits
          if digits
            Render.markdown_link_text(nav, "#{prefix}#{digits}.html")
          else
            nav
          end
        end
        "\< #{prev_text} \| #{next_text} \>"
      end
    end
  end
end
