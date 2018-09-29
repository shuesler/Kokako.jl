using Kokako, Test, GLPK

@testset "Forward Pass" begin
    model = Kokako.PolicyGraph(Kokako.LinearGraph(2),
                               optimizer = with_optimizer(GLPK.Optimizer)
                                   ) do node, stage
        @variable(node, x′ >= 0)
        @variable(node, x)
        Kokako.add_state_variable(node, :x, x, x′)
        Kokako.set_stage_objective(node, :Max, x′)
        Kokako.parameterize(node, stage * [1, 3], [0.5, 0.5]) do ω
            JuMP.set_upper_bound(x′, ω)
        end
    end
    scenario_path, sampled_states, cumulative_value = Kokako.forward_pass(model,
        Kokako.Options(Dict(:x=>1.0), Kokako.MonteCarlo()))
    simulated_value = 0.0
    for ((node_index, noise), state) in zip(scenario_path, sampled_states)
        @test state[:x] == noise
        simulated_value += noise
    end
    @test simulated_value == cumulative_value
end