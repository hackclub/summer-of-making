module Showcase
    class Matchmaker
        # my SO is a great matchmaker. hit me up on slack if you want lore!

        MAX_COMPOSITE_STDDEV = 0.5
        TARGET_VOTERS = 15
        WEIGHT_EXPOSURE = 0.6
        WEIGHT_UNCERTAINTY = 0.4
        SOFTMAX_TEMPERATURE = 1.0

        def initialize(user:)
            @user = user
        end

        def pick
            pool_project_ids = build_pool_project_ids
            return nil if pool_project_ids.empty?

            user_project = Project.where(id: pool_project_ids, user_id: @user.id).pluck(:id)
            already_voted = VoteMf.where(voter_id: @user.id, project_id: pool_project_ids).pluck(:project_id)

            excluded_ids = (user_project + already_voted).uniq
            candidate = pool_project_ids - excluded_ids
            return nil if candidate.empty?

            exposure_by_id = exposure_scores(candidate)
            uncertainty_by_id = uncertainty_scores(candidate)

            scores = candidate.index_with do |pid|
                (WEIGHT_EXPOSURE * (exposure_by_id[pid] || 0.0)) + (WEIGHT_UNCERTAINTY * (uncertainty_by_id[pid] || 0.0))
            end

            chosen_id = softmax(scores)
            Project.find_by(id: chosen_id)
        end

        private

        def build_pool_project_ids
              p = [ 2160,
                1779,
                9722,
                11764,
                792,
                2701,
                11177,
                11979,
                1469,
                12938,
                991,
                3423,
                1598,
                6392,
                12342,
                13073,
                10944,
                13782,
                169,
                6838,
                1775,
                914,
                1014,
                2521,
                133,
                8597,
                12542,
                1727,
                9530,
                947,
                10359,
                837,
                1932,
                12484,
                4041,
                53,
                398,
                7260,
                10992,
                4192,
                2179,
                2290,
                9969,
                12762,
                2365,
                5812,
                2753,
                13844,
                8326,
                6472,
                12114,
                3529,
                29,
                13227,
                1730,
                11304,
                1537,
                8244,
                161,
                196,
                4283,
                10458,
                4637,
                1131,
                13321,
                2787,
                4032,
                723,
                11162,
                7236,
                311,
                2470,
                7613,
                12158,
                13678,
                4907,
                2181,
                9065,
                4310,
                10026,
                2429,
                13952,
                3152,
                12344,
                3888,
                5038,
                664,
                3761,
                15,
                11442,
                6059,
                8920,
                5328,
                6737,
                12728,
                8994,
                791,
                5187,
                10803,
                5942 ]
              p & Project.where(id: p).pluck(:id)
        end

        def exposure_scores(project_ids)
            return {} if project_ids.empty?

            voters_count = VoteMf.where(project_id: project_ids).group(:project_id).distinct.count(:voter_id)
            project_ids.index_with do |p|
                v = voters_count[p].to_i
                ((TARGET_VOTERS - v) / TARGET_VOTERS.to_f).clamp(0.0, 1.0)
            end
        end

        def uncertainty_scores(project_ids)
            return {} if project_ids.empty?

            scores_by_project_id = Hash.new { |h, k| h[k] = [] }
            VoteMf.where(project_id: project_ids).select(:id, :project_id, :ballot).find_each(batch_size: 50) do |vmf|
                s = vmf.normalized_total_score
                scores_by_project_id[vmf.project_id] << s if s
            end

            project_ids.index_with do |pid|
                scores = scores_by_project_id[pid]
                next 1.0 if scores.empty?

                mean = scores.sum.to_f / scores.size
                var = scores.sum { |x| (x - mean) ** 2 } / scores.size.to_f
                std = Math.sqrt(var)
                (std / MAX_COMPOSITE_STDDEV).clamp(0.0, 1.0)
            end
        end

        def softmax(scores_by_id)
            return nil if scores_by_id.empty?

            ids = scores_by_id.keys
            values = ids.map { |id| scores_by_id[id].to_f }

            max_v = values.max
            temperature = [ SOFTMAX_TEMPERATURE.to_f, 1e-6 ].max
            exps = values.map { |v| Math.exp((v - max_v) / temperature) }
            sum = exps.sum
            return ids[values.index(max_v)] if sum <= 0.0

            probs = exps.map { |x| x / sum }
            r = rand
            cumulative = 0.0
            ids.each_with_index do |id, idx|
                cumulative += probs[idx]
                return id if r <= cumulative
            end
            ids.last
        end
    end
end
